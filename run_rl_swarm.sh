#!/usr/bin/env bash
set -euo pipefail

# === Define ROOT ===
ROOT="$PWD"
export ROOT

# === Define logs directory ===
mkdir -p "$ROOT/logs"
# ====================================

# === RESTART COUNTER & LOGGING ===
RESTART_COUNT_FILE="$ROOT/restart_count.txt"
RESTART_LOG_FILE="$ROOT/logs/restarts.log"

# Initialize or increment counter
if [ -f "$RESTART_COUNT_FILE" ]; then
    RESTART_COUNT=$(cat "$RESTART_COUNT_FILE")
else
    RESTART_COUNT=0
fi
RESTART_COUNT=$((RESTART_COUNT + 1))
echo "$RESTART_COUNT" > "$RESTART_COUNT_FILE"

# Log restart with timestamp
echo "=== RESTART #$RESTART_COUNT at $(date '+%Y-%m-%d %H:%M:%S %Z') ===" >> "$RESTART_LOG_FILE"
# =====================================

# Fix memory fragmentation
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# GenRL Swarm version to use
GENRL_TAG="0.1.11"
export IDENTITY_PATH
export GENSYN_RESET_CONFIG
export CONNECT_TO_TESTNET=true
export ORG_ID
export HF_HUB_DOWNLOAD_TIMEOUT=120 # 2 minutes
export SWARM_CONTRACT="0xFaD7C5e93f28257429569B854151A1B8DCD404c2"
export PRG_CONTRACT="0x51D4db531ae706a6eC732458825465058fA23a35"
export HUGGINGFACE_ACCESS_TOKEN="None"
export PRG_GAME=true
# Path to an RSA private key. If this path does not exist, a new key pair will be created.
# Remove this file if you want a new PeerID.
DEFAULT_IDENTITY_PATH="$ROOT"/swarm.pem
IDENTITY_PATH=${IDENTITY_PATH:-$DEFAULT_IDENTITY_PATH}
DOCKER=${DOCKER:-""}
GENSYN_RESET_CONFIG=${GENSYN_RESET_CONFIG:-""}
# Workaround for the non-root docker container.
if [ -n "$DOCKER" ]; then
    volumes=(
        /home/gensyn/rl_swarm/modal-login/temp-data
        /home/gensyn/rl_swarm/keys
        /home/gensyn/rl_swarm/configs
        /home/gensyn/rl_swarm/logs
    )
    for volume in ${volumes[@]}; do
        sudo chown -R 1001:1001 $volume
    done
fi
# Will ignore any visible GPUs if set.
CPU_ONLY=${CPU_ONLY:-""}
# Set if successfully parsed from modal-login/temp-data/userData.json.
ORG_ID=${ORG_ID:-""}
GREEN_TEXT="\033[32m"
BLUE_TEXT="\033[34m"
RED_TEXT="\033[31m"
RESET_TEXT="\033[0m"
echo_green() {
    echo -e "$GREEN_TEXT$1$RESET_TEXT"
}
echo_blue() {
    echo -e "$BLUE_TEXT$1$RESET_TEXT"
}
echo_red() {
    echo -e "$RED_TEXT$1$RESET_TEXT"
}
ROOT_DIR="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
# Function to clean up the server process upon exit
cleanup() {
    echo_green ">> Shutting down trainer..."
    # Remove modal credentials if they exist
    rm -r $ROOT_DIR/modal-login/temp-data/*.json 2> /dev/null || true
    # Kill all processes belonging to this script's process group
    kill -- -$$ || true
    exit 0
}
errnotify() {
    echo_red ">> An error was detected while running rl-swarm. See $ROOT/logs for full logs."
}
trap cleanup EXIT
trap errnotify ERR
echo -e "\033[38;5;224m"
cat << "EOF"
    ██████ ██ ███████ ██ ██ █████ ██████ ███ ███
    ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ████ ████
    ██████ ██ █████ ███████ ██ █ ██ ███████ ██████ ██ ████ ██
    ██ ██ ██ ██ ██ ███ ██ ██ ██ ██ ██ ██ ██ ██
    ██ ██ ███████ ███████ ███ ███ ██ ██ ██ ██ ██ ██
    From Gensyn (TANK by Django)
EOF
# Create logs directory if it doesn't exist
mkdir -p "$ROOT/logs"
if [ "$CONNECT_TO_TESTNET" = true ]; then
    # Run modal_login server.
  
# === START MODAL SERVER (SURVIVES RESTARTS) ===
if ! pgrep -f "yarn start" > /dev/null; then
    echo_green ">> Starting modal-login server (persistent)..."

    if [ ! -d "modal-login" ]; then
        echo_red "ERROR: modal-login/ missing!"
        exit 1
    fi

    cd modal-login

    # === MOVE ALL THIS HERE ===
    # Node.js + NVM
    if ! command -v node > /dev/null 2>&1; then
        # ... (full NVM install)
    else
        echo "Node.js is already installed: $(node -v)"
    fi

    # Yarn
    if ! command -v yarn > /dev/null 2>&1; then
        # ... (full yarn install)
    fi

    # Update .env
    ENV_FILE="$ROOT/modal-login/.env"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "3s/.*/SWARM_CONTRACT_ADDRESS=$SWARM_CONTRACT/" "$ENV_FILE"
        sed -i '' "4s/.*/PRG_CONTRACT_ADDRESS=$PRG_CONTRACT/" "$ENV_FILE"
    else
        sed -i "3s/.*/SWARM_CONTRACT_ADDRESS=$SWARM_CONTRACT/" "$ENV_FILE"
        sed -i "4s/.*/PRG_CONTRACT_ADDRESS=$PRG_CONTRACT/" "$ENV_FILE"
    fi
    # === END MOVE ===

    if [ ! -d "node_modules" ]; then
        echo_green ">> Installing modal-login dependencies..."
        yarn install --immutable >> "$ROOT/logs/yarn.log" 2>&1
    fi

    if [ ! -f "dist/index.js" ]; then
        echo_green ">> Building modal-login server..."
        yarn build >> "$ROOT/logs/yarn.log" 2>&1
    fi

    yarn start >> "$ROOT/logs/yarn.log" 2>&1 &
    SERVER_PID=$!
    disown $SERVER_PID
    cd ..

    echo_green ">> Waiting for modal server..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/api/health > /dev/null 2>&1; do
            echo_green ">> Modal server ready!"
            break
        fi
        sleep 1
    done
else
    echo_green ">> Modal server already running"
fi

    echo "Started server process: $SERVER_PID"
    sleep 5
    if [ -z "$DOCKER" ]; then
        if open http://localhost:3000 2> /dev/null; then
            echo_green ">> Successfully opened http://localhost:3000 in your default browser."
        else
            echo ">> Failed to open http://localhost:3000. Please open it manually."
        fi
    else
        echo_green ">> Please open http://localhost:3000 in your host browser."
    fi
    cd ..
    echo_green ">> Waiting for modal userData.json to be created..."
    while [ ! -f "modal-login/temp-data/userData.json" ]; do
        sleep 5
    done
    echo "Found userData.json. Proceeding..."
    ORG_ID=$(awk 'BEGIN { FS = "\"" } !/^[ \t]*[{}]/ { print $(NF - 1); exit }' modal-login/temp-data/userData.json)
    echo "Your ORG_ID is set to: $ORG_ID"
    echo "Waiting for API key to become activated..."
    while true; do
        STATUS=$(curl -s "http://localhost:3000/api/get-api-key-status?orgId=$ORG_ID")
        if [[ "$STATUS" == "activated" ]]; then
            echo "API key is activated! Proceeding..."
            break
        else
            echo "Waiting for API key to be activated..."
            sleep 5
        fi
    done
fi
echo_green ">> Getting requirements..."
pip install --upgrade pip
echo_green ">> Installing GenRL..."
pip install gensyn-genrl==${GENRL_TAG}
pip install reasoning-gym>=0.1.20
pip install hivemind@git+https://github.com/gensyn-ai/hivemind@639c964a8019de63135a2594663b5bec8e5356dd
# === INSTALL CUSTOM RGYM_EXP AS PACKAGE (FORCE REINSTALL) ===
echo_green ">> Installing custom rgym_exp module (force reinstall)..."
cd "$ROOT/rgym_exp"

# Uninstall old version if exists
pip uninstall -y rgym_exp 2>/dev/null || true

# Reinstall from current source
pip install -e . --no-deps || {
    echo_red "Failed to install rgym_exp. Check pyproject.toml and manager.py"
    exit 1
}
cd "$ROOT"
echo_green ">> Custom module installed and up-to-date!"
if [ ! -d "$ROOT/configs" ]; then
    mkdir "$ROOT/configs"
fi
if [ -f "$ROOT/configs/rg-swarm.yaml" ]; then
    if ! cmp -s "$ROOT/rgym_exp/config/rg-swarm.yaml" "$ROOT/configs/rg-swarm.yaml"; then
        if [ -z "$GENSYN_RESET_CONFIG" ]; then
            echo_green ">> Found differences in rg-swarm.yaml. If you would like to reset to the default, set GENSYN_RESET_CONFIG to a non-empty value."
        else
            echo_green ">> Found differences in rg-swarm.yaml. Backing up existing config."
            mv "$ROOT/configs/rg-swarm.yaml" "$ROOT/configs/rg-swarm.yaml.bak"
            cp "$ROOT/rgym_exp/config/rg-swarm.yaml" "$ROOT/configs/rg-swarm.yaml"
        fi
    fi
else
    cp "$ROOT/rgym_exp/config/rg-swarm.yaml" "$ROOT/configs/rg-swarm.yaml"
fi
if [ -n "$DOCKER" ]; then
    sudo chmod -R 0777 /home/gensyn/rl_swarm/configs
fi
echo_green ">> Done!"

# ------------------------------------------------------------------
# AUTO-ANSWER THE INTERACTIVE PROMPTS (if the vars are set)
# ------------------------------------------------------------------
: "${HUGGINGFACE_ACCESS_TOKEN:=}"
: "${MODEL_NAME:=}"
: "${PRG_GAME:=}"

# ---- HuggingFace upload ------------------------------------------------
if [ -z "$HUGGINGFACE_ACCESS_TOKEN" ]; then
    echo -en $GREEN_TEXT
    read -p ">> Would you like to push models you train in the RL swarm to the Hugging Face Hub? [y/N] " yn
    echo -en $RESET_TEXT
    yn=${yn:-N}
    case $yn in
        [Yy]*) read -p "Enter your Hugging Face access token: " HUGGINGFACE_ACCESS_TOKEN ;;
        *)     HUGGINGFACE_ACCESS_TOKEN="None" ;;
    esac
else
    echo ">> HuggingFace token pre-set – skipping prompt."
fi
export HUGGINGFACE_ACCESS_TOKEN

# ---- Model name --------------------------------------------------------
if [ -z "$MODEL_NAME" ]; then
    echo -en $GREEN_TEXT
    read -p ">> Enter the name of the model you want to use in huggingface repo/name format, or press [Enter] to use the default model. " MODEL_NAME
    echo -en $RESET_TEXT
fi
if [ -n "$MODEL_NAME" ]; then
    export MODEL_NAME
    echo_green ">> Using model: $MODEL_NAME"
else
    echo_green ">> Using default model from config"
fi

# ---- AI Prediction Market -----------------------------------------------
if [ -z "$PRG_GAME" ]; then
    echo -en $GREEN_TEXT
    read -p ">> Would you like your model to participate in the AI Prediction Market? [Y/n] " yn
    echo -en $RESET_TEXT
    if [[ "$yn" =~ ^[Nn]$ ]]; then
        PRG_GAME=false
    else
        PRG_GAME=true
    fi
else
    echo ">> PRG_GAME pre-set to $PRG_GAME – skipping prompt."
fi
export PRG_GAME
echo_green ">> Playing PRG game: $PRG_GAME"

echo_green ">> Good luck in the swarm!"
echo_blue ">> And remember to star the repo on GitHub! --> https://github.com/gensyn-ai/rl-swarm"

# ------------------------------------------------------------------
# THE ACTUAL TRAINER (ADDED FAULT TOLERANCE)
# ------------------------------------------------------------------
echo_green ">> Starting RL-Swarm trainer..."
set +e  # Let trainer crash — we restart
python -m rgym_exp.runner.swarm_launcher \
    --config-path "$ROOT/rgym_exp/config" \
    --config-name "rg-swarm.yaml"
EXIT_CODE=$?
set -e  # Safety back on
echo "=== Trainer exited with code $EXIT_CODE – restarting in 5 s ==="

# ------------------------------------------------------------------
# AUTO-RESTART LOOP
# ------------------------------------------------------------------
EXIT_CODE=$?
echo "=== Trainer exited with code $EXIT_CODE – restarting in 5 s ==="
sleep 5
# === Cleanup sockets & processes before restart ===
kill $(pgrep -P $$) 2>/dev/null || true
rm -f /tmp/hivemind-p2pd-*.sock
export P2P_CONTROL_PATH="/tmp/hivemind-p2pd-$(date +%s).sock"

exec "$0" "$@"
