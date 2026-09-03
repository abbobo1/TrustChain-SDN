# Live Demonstration Guide

## Before entering the presentation room

Run the automated tests and ensure all Fabric containers are healthy:

```bash
cd ~/TrustChain-SDN
source .venv/bin/activate
pytest -q
docker ps --format 'table {{.Names}}\t{{.Status}}'
```

Create `policy001` before the presentation if it is not already on the ledger.
Use four terminals so the audience can see each system layer separately.

## Terminal 1 — Blockchain network

```bash
cd ~/TrustChain-SDN
export TRUSTCHAIN_HOME="$PWD"
export FABRIC_SAMPLES_DIR="$PWD/fabric-samples"
export PATH="$FABRIC_SAMPLES_DIR/bin:$PATH"
cd "$FABRIC_SAMPLES_DIR/test-network"
export $(./setOrgEnv.sh Org1 | xargs)
export FABRIC_CFG_PATH="$FABRIC_SAMPLES_DIR/config"
peer chaincode query -C mychannel -n trustchain \
  -c '{"function":"ReadPolicy","Args":["policy001"]}'
```

Explain: “The policy is retrieved from Hyperledger Fabric; it is not hard-coded
inside the controller.”

## Terminal 2 — Blockchain API

```bash
cd ~/TrustChain-SDN
source .venv/bin/activate
export TRUSTCHAIN_HOME="$PWD"
export FABRIC_SAMPLES_DIR="$PWD/fabric-samples"
python blockchain-api/app.py
```

Leave this terminal running.

## Terminal 3 — API verification

```bash
curl -s http://localhost:5000/health | python3 -m json.tool
curl -s http://localhost:5000/policy/policy001 | python3 -m json.tool
```

Explain: “The API provides a controlled interface between the SDN component and
the blockchain network.”

## Terminal 4 — SDN policy decision

```bash
cd ~/TrustChain-SDN
source .venv/bin/activate
unset ODL_APPLY
python sdn-controller/controller.py
```

Point out the tenant, endpoints, action, status and resulting OpenFlow action.
State clearly that `DRY RUN` demonstrates deterministic translation without
changing a live switch. Do not claim that OpenDaylight installed a rule unless
the output explicitly says `Flow installed successfully`.

## Demonstrate verification tests

```bash
pytest -q
```

Explain that the tests cover health checking, unsafe policy IDs, Fabric-response
handling, ALLOW translation, DENY translation and inactive policies.

## Optional performance result

If the Fabric environment variables are still loaded:

```bash
cd ~/TrustChain-SDN
./benchmark_write_latency.sh
```

This takes about 30 seconds plus blockchain processing time. For a ten-minute
defense, it is safer to show previously generated CSV results and execute only
one functional policy query live.

## One-minute explanation

“TrustChain-SDN separates policy trust from network enforcement. A Go smart
contract records an immutable SDN policy in Hyperledger Fabric. The Flask API
queries that policy and returns structured JSON. The controller validates the
policy status and translates ALLOW into an OUTPUT:NORMAL flow or DENY into a
drop flow. The automated tests verify the translation independently, while the
Fabric query demonstrates that the policy comes from the blockchain ledger.”

## Recovery commands

If the API port is occupied:

```bash
sudo ss -ltnp | grep ':5000'
```

If Fabric is stopped:

```bash
cd ~/TrustChain-SDN/fabric-samples/test-network
./network.sh up createChannel -ca -c mychannel
```

If `peer` is not found:

```bash
export PATH="$HOME/TrustChain-SDN/fabric-samples/bin:$PATH"
```
