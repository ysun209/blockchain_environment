#!/bin/bash

# Simple and reliable validator key generation for Lighthouse

set -e

# Source environment variables
if [ -f .env ]; then
    source .env
fi

KEYSTORE_DIR=${KEYSTORE_DIR:-"./validator_keys"}
NUM_VALIDATORS=${NUM_VALIDATORS:-4}
PASSWORD="password123"

echo "🔑 Generating $NUM_VALIDATORS validator keys using Lighthouse account_manager..."

# Create directory
mkdir -p "$KEYSTORE_DIR"

# Method 1: Try the newer account_manager syntax
echo "Attempting to generate keys with account_manager..."
if docker run --rm -i \
  -v "$(pwd)/$KEYSTORE_DIR:/keys" \
  sigp/lighthouse:v4.5.0 \
  lighthouse \
  account_manager \
  validator \
  create \
  --base-dir=/keys \
  --count=$NUM_VALIDATORS \
  --password-file=/dev/stdin << EOF
$PASSWORD
EOF
then
    echo "✅ Successfully generated keys with account_manager"
else
    echo "⚠️  account_manager failed, trying alternative method..."
    
    # Method 2: Try with different syntax
    if docker run --rm -i \
      -v "$(pwd)/$KEYSTORE_DIR:/keys" \
      sigp/lighthouse:v4.5.0 \
      lighthouse \
      account_manager \
      validator \
      create \
      --base-dir=/keys \
      --count=$NUM_VALIDATORS \
      --password="$PASSWORD"
    then
        echo "✅ Successfully generated keys with alternative method"
    else
        echo "❌ Both methods failed. Let's try manual approach..."
        
        # Method 3: Generate keys one by one
        for i in $(seq 0 $((NUM_VALIDATORS-1))); do
            echo "Generating validator key $((i+1))/$NUM_VALIDATORS..."
            docker run --rm -i \
              -v "$(pwd)/$KEYSTORE_DIR:/keys" \
              sigp/lighthouse:v4.5.0 \
              lighthouse \
              account_manager \
              validator \
              create \
              --base-dir=/keys \
              --password="$PASSWORD" || echo "Failed to generate key $((i+1))"
        done
    fi
fi

# Create password file
echo "$PASSWORD" > "$KEYSTORE_DIR/password.txt"

# Check if any keys were generated
if ls "$KEYSTORE_DIR"/validator_keys/*/voting-keystore-*.json > /dev/null 2>&1; then
    KEY_COUNT=$(ls "$KEYSTORE_DIR"/validator_keys/*/voting-keystore-*.json | wc -l)
    echo "✅ Successfully generated $KEY_COUNT validator key(s)!"
    echo "📂 Keys saved to: $KEYSTORE_DIR"
    echo "🔑 Password: $PASSWORD"
    
    # List generated keys
    echo ""
    echo "📋 Generated validator keys:"
    for keyfile in "$KEYSTORE_DIR"/validator_keys/*/voting-keystore-*.json; do
        if [ -f "$keyfile" ]; then
            pubkey=$(jq -r '.pubkey' "$keyfile" 2>/dev/null || echo "unknown")
            echo "  - $pubkey"
        fi
    done
else
    echo "❌ No validator keys were generated successfully!"
    echo "💡 You may need to generate keys manually or use a different method."
    exit 1
fi