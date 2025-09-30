#!/bin/bash

# Simple key generation for lighthouse validator
# This script generates validator keys using lighthouse's built-in key generation

set -e

# Source environment variables
if [ -f .env ]; then
    source .env
fi

KEYSTORE_DIR=${KEYSTORE_DIR:-"./validator_keys"}
NUM_VALIDATORS=${NUM_VALIDATORS:-4}

echo "🔑 Generating $NUM_VALIDATORS validator keys using lighthouse..."

# Create directory
mkdir -p "$KEYSTORE_DIR"

# Generate keys using lighthouse
docker run --rm -it \
  -v "$(pwd)/$KEYSTORE_DIR:/keys" \
  sigp/lighthouse:v4.5.0 \
  lighthouse \
  account \
  validator \
  new \
  --count=$NUM_VALIDATORS \
  --base-dir=/keys \
  --password-file=/dev/stdin << EOF
password123
EOF

# Create password file
echo "password123" > "$KEYSTORE_DIR/password.txt"

echo "✅ Validator keys generated successfully!"
echo "📂 Keys saved to: $KEYSTORE_DIR"