#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 POLICY_ID" >&2
    exit 2
fi

PROJECT_ROOT="${TRUSTCHAIN_HOME:-$HOME/TrustChain-SDN}"
FABRIC_SAMPLES="${FABRIC_SAMPLES_DIR:-$PROJECT_ROOT/fabric-2.5.16/fabric-samples}"

# Add Fabric binaries to PATH
export PATH="$FABRIC_SAMPLES/bin:$PATH"

# Move to Fabric test network
cd "$FABRIC_SAMPLES/test-network"

# Load Org1 environment
export $(./setOrgEnv.sh Org1 | xargs)

# Use Fabric default configuration
export FABRIC_CFG_PATH="$PROJECT_ROOT/blockchain-api/fabric-config"

# Query blockchain policy
peer chaincode query \
-C mychannel \
-n trustchain \
-c '{"function":"ReadPolicy","Args":["'"$1"'"]}'
