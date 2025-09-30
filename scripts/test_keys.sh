#!/bin/bash

# Test validator key generation

set -e

echo "🧪 Testing validator key generation..."

# Create test directory
TEST_DIR="./test_keys"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

echo "📁 Test directory created: $TEST_DIR"

# Test eth2-val-tools method
echo ""
echo "🔑 Testing eth2-val-tools method..."
docker run --rm \
  -v "$(pwd)/$TEST_DIR:/keys" \
  protolambda/eth2-val-tools:latest \
  keystores \
  --source-mnemonic="abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about" \
  --source-min=0 \
  --source-max=2 \
  --out-loc="/keys" \
  --prysm-pass="password123"

# Check results
echo ""
echo "📋 Generated files:"
ls -la "$TEST_DIR"

if ls "$TEST_DIR"/*.json > /dev/null 2>&1; then
    KEY_COUNT=$(ls "$TEST_DIR"/*.json | wc -l)
    echo "✅ Successfully generated $KEY_COUNT validator key files!"
    
    # Show first keystore details
    echo ""
    echo "📄 Sample keystore content:"
    FIRST_KEY=$(ls "$TEST_DIR"/*.json | head -1)
    echo "File: $(basename "$FIRST_KEY")"
    jq . "$FIRST_KEY" 2>/dev/null || cat "$FIRST_KEY"
else
    echo "❌ No keystore files generated"
fi

# Cleanup
echo ""
echo "🧹 Cleaning up test directory..."
rm -rf "$TEST_DIR"

echo "✅ Test completed!"