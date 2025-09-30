#!/bin/bash

# Reset the blockchain network (clean slate)

set -e

echo "🧹 Resetting Private Ethereum PoS Network"
echo "========================================"
echo ""
echo "⚠️  WARNING: This will:"
echo "   - Stop all running containers"
echo "   - Remove all blockchain data"
echo "   - Remove all Docker volumes"
echo "   - Keep genesis and validator keys"
echo ""

read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Reset cancelled"
    exit 1
fi

echo ""
echo "🛑 Stopping all services..."
docker compose down

echo ""
echo "🗑️  Removing Docker volumes..."
docker volume rm \
  blockchain_environment_el_data \
  blockchain_environment_cl_data \
  blockchain_environment_vc_data \
  blockchain_environment_blockscout_db \
  blockchain_environment_blockscout_logs \
  2>/dev/null || echo "Some volumes were already removed or don't exist"

echo ""
echo "🧹 Cleaning up data directories..."
rm -rf data/el/* data/cl/* data/vc/* 2>/dev/null || true

echo ""
echo "✅ Network reset complete!"
echo ""
echo "🚀 To restart the network:"
echo "   docker compose up -d"
echo ""
echo "📝 Note: Genesis and validator keys are preserved"