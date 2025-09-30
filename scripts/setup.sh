#!/bin/bash

# Complete setup script for Private Ethereum PoS network

set -e

echo "🚀 Setting up Private Ethereum PoS Network"
echo "=========================================="

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose and try again."
    exit 1
fi

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✅ Please review and edit .env file with your desired configuration"
fi

# Source environment variables
source .env

echo ""
echo "🔧 Configuration:"
echo "  Chain ID: $CHAIN_ID"
echo "  Network Name: $NETWORK_NAME"
echo "  Genesis Dir: $GENESIS_DIR"
echo "  Validator Keys Dir: $KEYSTORE_DIR"

# Create necessary directories
echo ""
echo "📁 Creating directories..."
mkdir -p "$GENESIS_DIR/el"
mkdir -p "$GENESIS_DIR/cl"
mkdir -p "secrets"
mkdir -p "$KEYSTORE_DIR"
mkdir -p "data/el"
mkdir -p "data/cl"
mkdir -p "data/vc"

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh

# Check if genesis already exists
if [ ! -f "$GENESIS_DIR/genesis.json" ]; then
    echo ""
    echo "⚡ Generating genesis configuration..."
    ./scripts/genesis.sh
else
    echo "✅ Genesis already exists, skipping generation"
fi

# Check if validator keys exist
if [ ! -d "$KEYSTORE_DIR" ] || [ ! -f "$KEYSTORE_DIR/password.txt" ] || [ -z "$(ls -A $KEYSTORE_DIR 2>/dev/null)" ]; then
    echo ""
    echo "🔑 Generating validator keys..."
    
    # Use eth2-val-tools for reliable key generation
    echo "Using eth2-val-tools for validator key generation..."
    mkdir -p "$KEYSTORE_DIR"
    
    # Generate validator keys using eth2-val-tools
    docker run --rm \
      -v "$(pwd)/$KEYSTORE_DIR:/keys" \
      protolambda/eth2-val-tools:latest \
      keystores \
      --source-mnemonic="abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about" \
      --source-min=0 \
      --source-max=4 \
      --out-loc="/keys" \
      --prysm-pass="password123"
    
    # Create password file
    echo "password123" > "$KEYSTORE_DIR/password.txt"
    
    echo "✅ Validator keys generated"
else
    echo "✅ Validator keys already exist, skipping generation"
fi

echo ""
echo "🐳 Starting the blockchain network..."
echo "This may take a few minutes on first run as Docker images are downloaded..."

# Start the core network first
docker compose up -d el-1-geth-lighthouse cl-1-lighthouse-geth vc-1-geth-lighthouse

echo ""
echo "⏳ Waiting for network to initialize..."
sleep 30

# Start the explorer stack
echo "🔍 Starting explorer services..."
docker compose up -d blockscout-postgres blockscout blockscout-frontend blockscout-verif

echo ""
echo "✅ Network started successfully!"
echo ""
echo "🌐 Access Points:"
echo "  📊 Blockscout Explorer: http://localhost:${BLOCKSCOUT_FRONTEND_PORT:-3000}"
echo "  🔗 Geth RPC: http://localhost:${EL_RPC_PORT:-8545}"
echo "  🔗 Geth WebSocket: ws://localhost:${EL_WS_PORT:-8546}"
echo "  ⛓️  Lighthouse Beacon API: http://localhost:${CL_HTTP_PORT:-4000}"
echo ""
echo "📊 Metrics:"
echo "  🔗 Geth Metrics: http://localhost:${EL_METRICS_PORT:-9001}/debug/metrics"
echo "  ⛓️  Lighthouse Beacon Metrics: http://localhost:${CL_METRICS_PORT:-5054}/metrics"
echo "  👤 Lighthouse Validator Metrics: http://localhost:${VC_METRICS_PORT:-8080}/metrics"
echo ""
echo "🔑 Prefunded Accounts:"
echo "  - 0x8943545177806ED17B9F23F0a21ee5948eCaa776"
echo "  - 0x27eE006a4c4c81642b0cBdB1F0d21FbC3a05b777"
echo "  Password: password123"
echo ""
echo "🚀 Network is ready for use!"
echo ""
echo "📝 Common commands:"
echo "  docker compose ps                    # Check service status"
echo "  docker compose logs -f [service]    # View logs"
echo "  docker compose down                 # Stop all services"
echo "  docker compose down -v             # Stop and remove volumes (reset network)"
echo ""
echo "🔧 To start Dora UI (optional):"
echo "  docker compose --profile dora up -d dora"
echo "  Access at: http://localhost:${DORA_PORT:-8081}"