# TrustChain-SDN

TrustChain-SDN is a research prototype that stores software-defined networking
(SDN) policies in Hyperledger Fabric, exposes them through a Flask API, and
translates active `ALLOW` or `DENY` policies into OpenFlow-style rules for
OpenDaylight.

## Architecture

1. The Go smart contract stores and retrieves an `SDNPolicy` on Fabric.
2. The Flask API queries Fabric and returns the policy as JSON.
3. The Python controller obtains the policy and makes an enforcement decision.
4. In the default dry-run mode, the controller displays the proposed rule.
5. With `ODL_APPLY=true`, it submits the rule to OpenDaylight through RESTCONF.

## Repository layout

| Path | Purpose |
| --- | --- |
| `trustchain-smartcontract/` | Hyperledger Fabric Go chaincode |
| `blockchain-api/` | Flask API and Fabric query script |
| `sdn-controller/` | Policy decision and OpenDaylight integration |
| `opendaylight/` | OpenDaylight container definition |
| `tests/` | Automated API and controller tests |
| `docs/TEST_SCENARIOS.md` | Functional and performance scenarios |
| `docs/LIVE_DEMO.md` | Ordered demonstration procedure |
| `benchmark_*.sh` | Throughput and write-latency experiments |

Hyperledger Fabric itself is intentionally not committed. The official samples,
Docker images, generated certificates, ledgers and binaries are dependencies,
not project source code.

## Prerequisites

- Kali Linux or Ubuntu Linux
- Git, curl and Bash
- Python 3.10 or newer
- Go 1.20 or newer
- Docker Engine with the Compose plugin
- Hyperledger Fabric 2.5.16 and Fabric CA 1.5.17

Confirm the main tools:

```bash
git --version
python3 --version
go version
docker --version
docker compose version
```

## Clone and install Python dependencies

```bash
git clone https://github.com/YOUR-USERNAME/TrustChain-SDN.git
cd TrustChain-SDN
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

## Install Hyperledger Fabric

From the repository root, download Fabric 2.5.16, Fabric CA 1.5.17, binaries,
samples and images:

```bash
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh
chmod +x install-fabric.sh
./install-fabric.sh --fabric-version 2.5.16 --ca-version 1.5.17 docker binary samples
```

Set the project paths for the current terminal:

```bash
export TRUSTCHAIN_HOME="$PWD"
export FABRIC_SAMPLES_DIR="$PWD/fabric-samples"
export PATH="$FABRIC_SAMPLES_DIR/bin:$PATH"
export FABRIC_CFG_PATH="$FABRIC_SAMPLES_DIR/config"
```

## Build and deploy the smart contract

Check the Go module first:

```bash
cd "$TRUSTCHAIN_HOME/trustchain-smartcontract"
go mod download
go test ./...
```

Start the two-organization Fabric test network and deploy the chaincode:

```bash
cd "$FABRIC_SAMPLES_DIR/test-network"
./network.sh down
./network.sh up createChannel -ca -c mychannel
./network.sh deployCC -ccn trustchain \
  -ccp "$TRUSTCHAIN_HOME/trustchain-smartcontract" \
  -ccl go
```

Load the Org1 command environment:

```bash
export $(./setOrgEnv.sh Org1 | xargs)
export FABRIC_CFG_PATH="$FABRIC_SAMPLES_DIR/config"
```

Create and query a demonstration policy:

```bash
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" \
  -C mychannel -n trustchain \
  --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
  --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
  -c '{"function":"CreatePolicy","Args":["policy001","tenantA","10.0.1.1/32","10.0.2.1/32","ALLOW","100","Admin"]}'

peer chaincode query -C mychannel -n trustchain \
  -c '{"function":"ReadPolicy","Args":["policy001"]}'
```

Wait several seconds after an invoke before querying if the committed value is
not immediately visible.

## Run the Blockchain API

Open a new terminal:

```bash
cd ~/TrustChain-SDN
source .venv/bin/activate
export TRUSTCHAIN_HOME="$PWD"
export FABRIC_SAMPLES_DIR="$PWD/fabric-samples"
python blockchain-api/app.py
```

Test it from another terminal:

```bash
curl http://localhost:5000/health
curl http://localhost:5000/policy/policy001
```

## Run the controller

Dry run is the safe default and does not require OpenDaylight:

```bash
cd ~/TrustChain-SDN
source .venv/bin/activate
python sdn-controller/controller.py
```

To request real rule installation, start OpenDaylight and explicitly enable it:

```bash
docker compose -f opendaylight/docker-compose.yml up -d
export ODL_APPLY=true
export ODL_NODE=openflow:1
python sdn-controller/controller.py
```

OpenDaylight RESTCONF paths differ between distributions. Verify the image and
RESTCONF endpoint in your environment before using real mode. The dry-run output
remains the reproducible demonstration of policy translation.

## Tests

```bash
source .venv/bin/activate
pytest -q
```

The tests do not need Fabric or OpenDaylight; external calls are isolated so the
API validation and policy-to-flow translation can be checked independently.

## Benchmarks

Run benchmarks only after loading the Org1 environment variables in the Fabric
test-network terminal:

```bash
cd "$TRUSTCHAIN_HOME"
chmod +x benchmark_throughput.sh benchmark_write_latency.sh
./benchmark_throughput.sh
./benchmark_write_latency.sh
```

CSV and raw-log files are generated locally and ignored by Git.

## Security and limitations

- Never commit `.env`, private keys, generated Fabric organizations or wallets.
- Flask debug mode is disabled unless `FLASK_DEBUG=true` is explicitly set.
- The included Fabric network is a local development network, not production.
- OpenDaylight credentials must be replaced before any non-laboratory use.
- `ALLOW` uses the OpenFlow `NORMAL` output action; `DENY` creates a drop rule.
- The API runs without TLS for local demonstration only.

See [`docs/LIVE_DEMO.md`](docs/LIVE_DEMO.md) for the defense sequence and
[`docs/TEST_SCENARIOS.md`](docs/TEST_SCENARIOS.md) for expected results. Follow
[`docs/GITHUB_UPLOAD.md`](docs/GITHUB_UPLOAD.md) to publish the repository.
