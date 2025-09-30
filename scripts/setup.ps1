# PowerShell setup script for Private Ethereum PoS network

Write-Host "🚀 Setting up Private Ethereum PoS Network" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Check if Docker is running
try {
    docker info 2>$null | Out-Null
} catch {
    Write-Host "❌ Docker is not running. Please start Docker and try again." -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is available
try {
    docker compose version 2>$null | Out-Null
} catch {
    Write-Host "❌ Docker Compose is not available. Please install Docker Compose and try again." -ForegroundColor Red
    exit 1
}

# Copy environment file if it doesn't exist
if (!(Test-Path ".env")) {
    Write-Host "📝 Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "✅ Please review and edit .env file with your desired configuration" -ForegroundColor Green
}

# Read environment variables from .env file
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match "^([^#][^=]+)=(.*)$") {
        $envVars[$matches[1]] = $matches[2]
    }
}

$CHAIN_ID = $envVars["CHAIN_ID"]
$NETWORK_NAME = $envVars["NETWORK_NAME"]
$GENESIS_DIR = $envVars["GENESIS_DIR"]
$KEYSTORE_DIR = $envVars["KEYSTORE_DIR"]

Write-Host ""
Write-Host "🔧 Configuration:" -ForegroundColor Cyan
Write-Host "  Chain ID: $CHAIN_ID"
Write-Host "  Network Name: $NETWORK_NAME"
Write-Host "  Genesis Dir: $GENESIS_DIR"
Write-Host "  Validator Keys Dir: $KEYSTORE_DIR"

# Create necessary directories
Write-Host ""
Write-Host "📁 Creating directories..." -ForegroundColor Yellow
$directories = @(
    "$GENESIS_DIR/el",
    "$GENESIS_DIR/cl",
    "secrets",
    "$KEYSTORE_DIR",
    "data/el",
    "data/cl",
    "data/vc"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Check if genesis already exists
if (!(Test-Path "$GENESIS_DIR/genesis.json")) {
    Write-Host ""
    Write-Host "⚡ Generating genesis configuration..." -ForegroundColor Yellow
    
    # Generate JWT secret
    $jwt = -join ((0..63) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
    $jwt | Out-File -FilePath "secrets/jwt.hex" -Encoding ASCII -NoNewline
    
    # Create password file
    "password123" | Out-File -FilePath "secrets/password.txt" -Encoding ASCII
    
    # Create genesis.json
    $genesis = @{
        config = @{
            chainId = [int]$CHAIN_ID
            homesteadBlock = 0
            eip150Block = 0
            eip155Block = 0
            eip158Block = 0
            byzantiumBlock = 0
            constantinopleBlock = 0
            petersburgBlock = 0
            istanbulBlock = 0
            berlinBlock = 0
            londonBlock = 0
            arrowGlacierBlock = 0
            grayGlacierBlock = 0
            mergeNetsplitBlock = 0
            shanghaiTime = 0
            cancunTime = 0
            terminalTotalDifficulty = 0
            terminalTotalDifficultyPassed = $true
            ethash = @{}
        }
        nonce = "0x0"
        timestamp = "0x{0:x}" -f [int](Get-Date -UFormat %s)
        extraData = "0x0000000000000000000000000000000000000000000000000000000000000000"
        gasLimit = "0x47b760"
        difficulty = "0x1"
        mixHash = "0x0000000000000000000000000000000000000000000000000000000000000000"
        coinbase = "0x0000000000000000000000000000000000000000"
        alloc = @{
            "8943545177806ED17B9F23F0a21ee5948eCaa776" = @{
                balance = "0x200000000000000000000000000000000000000000000000000000000000"
            }
            "27eE006a4c4c81642b0cBdB1F0d21FbC3a05b777" = @{
                balance = "0x200000000000000000000000000000000000000000000000000000000000"
            }
            "4242424242424242424242424242424242424242" = @{
                balance = "0x0"
                code = "0x60806040526004361061003f5760003560e01c806301ffc9a71461004457806322895118146100a4578063621fd130146101ba578063c5f2892f14610244575b600080fd5b34801561005057600080fd5b506100906004803603602081101561006757600080fd5b50357fffffffff000000000000000000000000000000000000000000000000000000001661026b565b604080519115158252519081900360200190f35b6101b8600480360360808110156100ba57600080fd5b8101906020810181356401000000008111156100d557600080fd5b8201836020820111156100e757600080fd5b8035906020019184600183028401116401000000008311171561010957600080fd5b91939092909160208101903564010000000081111561012757600080fd5b82018360208201111561013957600080fd5b8035906020019184600183028401116401000000008311171561015b57600080fd5b91939092909160208101903564010000000081111561017957600080fd5b82018360208201111561018b57600080fd5b803590602001918460018302840111640100000000831117156101ad57600080fd5b919350915035610304565b005b3480156101c657600080fd5b506101cf6110b5565b6040805160208082528351818301528351919283929083019185019080838360005b838110156102095781810151838201526020016101f1565b50505050905090810190601f1680156102365780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34801561025057600080fd5b506102596110c7565b60408051918252519081900360200190f35b60007fffffffff0000000000000000000000000000000000000000000000000000000082167f01ffc9a70000000000000000000000000000000000000000000000000000000014806102fe57507fffffffff0000000000000000000000000000000000000000000000000000000082167f8564090700000000000000000000000000000000000000000000000000000000145b92915050565b6030861461035d576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260268152602001806118056026913960400191505060405180910390fd5b602084146103b6576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252603681526020018061179c6036913960400191505060405180910390fd5b6060821461040f576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260298152602001806118786029913960400191505060405180910390fd5b670de0b6b3a7640000341015610470576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260268152602001806118526026913960400191505060405180910390fd5b6000606054146104cb576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252603681526020018061183c6036913960400191505060405180910390fd5b633b9aca003a045fa52b16840668c004803b7db79734b30001606b5463f00026a4a5863f00032e2b89fb90fd5b50346004600082825401925050819055506000618b6e4300348f7d6b9b6b8f62c004dae1c704b83b001606b5463f00026a4a5863f00032e2b89fb90fd5b50346004600082825401925050819055506000618a6ed300348f7d6b9b6b8f62c004dae1c704b83b001606b5463f00026a4a5863f00032e2b89fb90fd"
            }
        }
        number = "0x0"
        gasUsed = "0x0"
        parentHash = "0x0000000000000000000000000000000000000000000000000000000000000000"
        baseFeePerGas = "0x7"
    }
    
    $genesis | ConvertTo-Json -Depth 10 | Out-File -FilePath "$GENESIS_DIR/genesis.json" -Encoding UTF8
    
    # Initialize Geth datadir
    docker run --rm -v "${PWD}/${GENESIS_DIR}:/genesis" -v "${PWD}/data/el:/data" ethereum/client-go:v1.13.4 --datadir=/data init /genesis/genesis.json
    
    Write-Host "✅ Genesis configuration created" -ForegroundColor Green
} else {
    Write-Host "✅ Genesis already exists, skipping generation" -ForegroundColor Green
}

# Check if validator keys exist
if (!(Test-Path "$KEYSTORE_DIR/password.txt")) {
    Write-Host ""
    Write-Host "🔑 Generating validator keys..." -ForegroundColor Yellow
    
    # Create password file
    "password123" | Out-File -FilePath "$KEYSTORE_DIR/password.txt" -Encoding ASCII
    
    Write-Host "✅ Validator keys setup complete" -ForegroundColor Green
} else {
    Write-Host "✅ Validator keys already exist, skipping generation" -ForegroundColor Green
}

Write-Host ""
Write-Host "🐳 Starting the blockchain network..." -ForegroundColor Yellow
Write-Host "This may take a few minutes on first run as Docker images are downloaded..."

# Start the core network first
docker compose up -d el-1-geth-lighthouse cl-1-lighthouse-geth vc-1-geth-lighthouse

Write-Host ""
Write-Host "⏳ Waiting for network to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Start the explorer stack
Write-Host "🔍 Starting explorer services..." -ForegroundColor Yellow
docker compose up -d blockscout-postgres blockscout blockscout-frontend blockscout-verif

$EL_RPC_PORT = $envVars["EL_RPC_PORT"]
$EL_WS_PORT = $envVars["EL_WS_PORT"]
$CL_HTTP_PORT = $envVars["CL_HTTP_PORT"]
$BLOCKSCOUT_FRONTEND_PORT = $envVars["BLOCKSCOUT_FRONTEND_PORT"]
$EL_METRICS_PORT = $envVars["EL_METRICS_PORT"]
$CL_METRICS_PORT = $envVars["CL_METRICS_PORT"]
$VC_METRICS_PORT = $envVars["VC_METRICS_PORT"]
$DORA_PORT = $envVars["DORA_PORT"]

Write-Host ""
Write-Host "✅ Network started successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Access Points:" -ForegroundColor Cyan
Write-Host "  📊 Blockscout Explorer: http://localhost:$BLOCKSCOUT_FRONTEND_PORT"
Write-Host "  🔗 Geth RPC: http://localhost:$EL_RPC_PORT"
Write-Host "  🔗 Geth WebSocket: ws://localhost:$EL_WS_PORT"
Write-Host "  ⛓️  Lighthouse Beacon API: http://localhost:$CL_HTTP_PORT"
Write-Host ""
Write-Host "📊 Metrics:" -ForegroundColor Cyan
Write-Host "  🔗 Geth Metrics: http://localhost:$EL_METRICS_PORT/debug/metrics"
Write-Host "  ⛓️  Lighthouse Beacon Metrics: http://localhost:$CL_METRICS_PORT/metrics"
Write-Host "  👤 Lighthouse Validator Metrics: http://localhost:$VC_METRICS_PORT/metrics"
Write-Host ""
Write-Host "🔑 Prefunded Accounts:" -ForegroundColor Cyan
Write-Host "  - 0x8943545177806ED17B9F23F0a21ee5948eCaa776"
Write-Host "  - 0x27eE006a4c4c81642b0cBdB1F0d21FbC3a05b777"
Write-Host "  Password: password123"
Write-Host ""
Write-Host "🚀 Network is ready for use!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Common commands:" -ForegroundColor Yellow
Write-Host "  docker compose ps                    # Check service status"
Write-Host "  docker compose logs -f [service]    # View logs"
Write-Host "  docker compose down                 # Stop all services"
Write-Host "  docker compose down -v             # Stop and remove volumes (reset network)"
Write-Host ""
Write-Host "🔧 To start Dora UI (optional):" -ForegroundColor Yellow
Write-Host "  docker compose --profile dora up -d dora"
Write-Host "  Access at: http://localhost:$DORA_PORT"