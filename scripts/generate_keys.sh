#!/bin/bash

# Simple key generation using eth2-val-tools (more reliable)
# This script generates validator keys using eth2-val-tools

set -e

# Source environment variables
if [ -f .env ]; then
    source .env
fi

KEYSTORE_DIR=${KEYSTORE_DIR:-"./validator_keys"}
NUM_VALIDATORS=${NUM_VALIDATORS:-4}
MNEMONIC=${MNEMONIC:-"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"}

echo "🔑 Generating $NUM_VALIDATORS validator keys using eth2-val-tools..."

# Create directory
mkdir -p "$KEYSTORE_DIR"

# Generate validator keys using eth2-val-tools (more reliable)
docker run --rm \
  -v "$(pwd)/$KEYSTORE_DIR:/keys" \
  protolambda/eth2-val-tools:latest \
  keystores \
  --source-mnemonic="$MNEMONIC" \
  --source-min=0 \
  --source-max=$NUM_VALIDATORS \
  --out-loc="/keys" \
  --prysm-pass="password123"

# Create password file
echo "password123" > "$KEYSTORE_DIR/password.txt"

echo "✅ Validator keys generated successfully!"
echo "📂 Keys saved to: $KEYSTORE_DIR"
echo "🔑 Using mnemonic: $MNEMONIC"
echo "🔑 Password: password123"

# List generated keys
if ls "$KEYSTORE_DIR"/*.json > /dev/null 2>&1; then
    echo ""
    echo "📋 Generated files:"
    ls -la "$KEYSTORE_DIR"/*.json 2>/dev/null || echo "No JSON keystore files found"
fi