#!/bin/bash

# Validator key generation script for Private Ethereum PoS network

set -e

# Source environment variables
if [ -f .env ]; then
    source .env
fi

# Default values
KEYSTORE_DIR=${KEYSTORE_DIR:-"./validator_keys"}
GENESIS_DIR=${GENESIS_DIR:-"./genesis"}
NUM_VALIDATORS=${NUM_VALIDATORS:-4}
MNEMONIC=${MNEMONIC:-"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"}

echo "🔑 Generating $NUM_VALIDATORS validator keys..."

# Create directories
mkdir -p "$KEYSTORE_DIR"
mkdir -p "$GENESIS_DIR/cl"

# Generate validator keys using eth2-val-tools
docker run --rm \
  -v "$(pwd)/$KEYSTORE_DIR:/keys" \
  -v "$(pwd)/$GENESIS_DIR:/genesis" \
  protolambda/eth2-val-tools:latest \
  keystores \
  --source-mnemonic="$MNEMONIC" \
  --source-min=0 \
  --source-max=$NUM_VALIDATORS \
  --out-loc="/keys" \
  --prysm-pass="password123"

# Create password file
echo "password123" > "$KEYSTORE_DIR/password.txt"

# Generate deposit data
docker run --rm \
  -v "$(pwd)/$KEYSTORE_DIR:/keys" \
  -v "$(pwd)/$GENESIS_DIR:/genesis" \
  protolambda/eth2-val-tools:latest \
  deposit-data \
  --source-mnemonic="$MNEMONIC" \
  --source-min=0 \
  --source-max=$NUM_VALIDATORS \
  --amount=32000000000 \
  --fork-version=0x00000000 \
  --withdrawals-mnemonic="$MNEMONIC" \
  --withdrawals-min=0 \
  --withdrawals-max=$NUM_VALIDATORS \
  --out-loc="/genesis/cl"

# Generate CL genesis using lcli
GENESIS_TIME=$(date +%s)
echo "⏰ Using genesis time: $GENESIS_TIME"

docker run --rm \
  -v "$(pwd)/$GENESIS_DIR:/genesis" \
  sigp/lighthouse:v4.5.0 \
  lcli \
  new-testnet \
  --testnet-dir=/genesis/cl \
  --deposit-contract-address=0x4242424242424242424242424242424242424242 \
  --deposit-contract-deploy-block=0 \
  --eth1-block-hash=0x0000000000000000000000000000000000000000000000000000000000000000 \
  --eth1-id=$CHAIN_ID \
  --min-genesis-active-validator-count=$NUM_VALIDATORS \
  --min-genesis-time=$GENESIS_TIME \
  --genesis-delay=30 \
  --genesis-fork-version=0x00000000 \
  --altair-fork-epoch=0 \
  --bellatrix-fork-epoch=0 \
  --capella-fork-epoch=0 \
  --deneb-fork-epoch=0 \
  --seconds-per-slot=12 \
  --seconds-per-eth1-block=14

echo "✅ Validator keys and CL genesis created successfully!"
echo ""
echo "📂 Files created:"
echo "  - $KEYSTORE_DIR/ (validator keystores and passwords)"
echo "  - $GENESIS_DIR/cl/genesis.ssz (CL genesis state)"
echo "  - $GENESIS_DIR/cl/config.yaml (CL configuration)"
echo ""
echo "🎯 Ready to start the network with:"
echo "    docker compose up -d"