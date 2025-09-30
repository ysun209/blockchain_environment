#!/bin/bash

# Network status and health check script

source .env

echo "🔍 Checking Private Ethereum PoS Network Status"
echo "=============================================="

# Function to check HTTP endpoint
check_endpoint() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_code"; then
        echo "✅ $name: $url"
    else
        echo "❌ $name: $url (not responding)"
    fi
}

# Function to check JSON-RPC endpoint
check_rpc() {
    local name=$1
    local url=$2
    local method=$3
    
    if response=$(curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\",\"params\":[]}"); then
        
        if echo "$response" | jq -e '.result' > /dev/null 2>&1; then
            result=$(echo "$response" | jq -r '.result')
            echo "✅ $name: $result"
        else
            echo "❌ $name: RPC error"
        fi
    else
        echo "❌ $name: Connection failed"
    fi
}

echo ""
echo "📊 Service Status:"
docker compose ps

echo ""
echo "🔗 Endpoint Health:"
check_endpoint "Geth RPC" "http://localhost:${EL_RPC_PORT:-8545}"
check_endpoint "Lighthouse Beacon API" "http://localhost:${CL_HTTP_PORT:-4000}/eth/v1/node/health"
check_endpoint "Blockscout Frontend" "http://localhost:${BLOCKSCOUT_FRONTEND_PORT:-3000}"
check_endpoint "Blockscout Backend" "http://localhost:${BLOCKSCOUT_BACKEND_PORT:-4001}/api/v1/health"

echo ""
echo "⛓️  Chain Status:"
check_rpc "Latest Block Number" "http://localhost:${EL_RPC_PORT:-8545}" "eth_blockNumber"
check_rpc "Chain ID" "http://localhost:${EL_RPC_PORT:-8545}" "eth_chainId"
check_rpc "Peer Count" "http://localhost:${EL_RPC_PORT:-8545}" "net_peerCount"

echo ""
echo "🗣️  Beacon Node Status:"
if beacon_status=$(curl -s "http://localhost:${CL_HTTP_PORT:-4000}/eth/v1/node/syncing"); then
    if echo "$beacon_status" | jq -e '.data.is_syncing == false' > /dev/null 2>&1; then
        echo "✅ Beacon Node: Synced"
        
        # Get head slot
        if head_info=$(curl -s "http://localhost:${CL_HTTP_PORT:-4000}/eth/v1/beacon/headers/head"); then
            head_slot=$(echo "$head_info" | jq -r '.data.header.message.slot')
            echo "✅ Head Slot: $head_slot"
        fi
    else
        echo "⏳ Beacon Node: Syncing..."
    fi
else
    echo "❌ Beacon Node: Connection failed"
fi

echo ""
echo "👤 Validator Status:"
if validators=$(curl -s "http://localhost:${CL_HTTP_PORT:-4000}/eth/v1/beacon/states/head/validators"); then
    active_count=$(echo "$validators" | jq '[.data[] | select(.status == "active_ongoing")] | length')
    total_count=$(echo "$validators" | jq '.data | length')
    echo "✅ Active Validators: $active_count / $total_count"
else
    echo "❌ Validators: Could not fetch status"
fi

echo ""
echo "💰 Account Balances:"
for account in "0x8943545177806ED17B9F23F0a21ee5948eCaa776" "0x27eE006a4c4c81642b0cBdB1F0d21FbC3a05b777"; do
    if balance_hex=$(curl -s -X POST "http://localhost:${EL_RPC_PORT:-8545}" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_getBalance\",\"params\":[\"$account\",\"latest\"]}" | \
        jq -r '.result'); then
        
        if [ "$balance_hex" != "null" ] && [ "$balance_hex" != "" ]; then
            # Convert hex to decimal and then to ETH
            balance_wei=$(printf "%d" "$balance_hex")
            balance_eth=$(echo "scale=6; $balance_wei / 1000000000000000000" | bc -l)
            echo "✅ $account: $balance_eth ETH"
        else
            echo "❌ $account: Could not fetch balance"
        fi
    else
        echo "❌ $account: Connection failed"
    fi
done

echo ""
echo "📈 Quick Stats:"
echo "  🌐 Network: http://localhost:${BLOCKSCOUT_FRONTEND_PORT:-3000}"
echo "  🔗 RPC: http://localhost:${EL_RPC_PORT:-8545}"
echo "  ⛓️  Beacon: http://localhost:${CL_HTTP_PORT:-4000}"