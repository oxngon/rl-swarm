# RL Swarm

This fork is **battle-tested Gensyn RL-Swarm node** with built in monitor and bulletproof autorestart. It includes better memory management, improvements to avoid OOM errors, better handling of DHT errors due to peer poisoining and crashes due to socket conflicts. Intended for advanced node runners. 

### Improvements/changes

| File | Feature | Benefit |
|--------|--------|--------|
| **run_rl_swarm.sh** | **auto-restart loop** | node restarts automatically in case of crash |
| **run_rl_swarm.sh** | **restart counter & logging** | easily check for crashes in `logs/restarts.log` |
| **run_rl_swarm.sh** | **VRAM management** | fixes memory fragmentation |
| **manager.py** | **DHT reconnect** | better stability and resilence during peer poisoning or network/p2pd drop|
| **manager.py** | **bootnodes reinjection** | skips round if unrecoverable, better node stability and resilence |
| **manager.py** | **silenced hivemind noise** | prevents tokenizer deadlocks, better node stability and resilence |
| **rl-swarm.yaml** | **bfloat16 + gradient checkpoint** | memory optimisation |
| **rl-swarm.yaml** | **smaller beam (50 -> 30)** | memory optimisation  |
| **rl-swarm.yaml** | **minimal sampling** | memory optimisation  |

### IMPORTANT
Before running export these variables to answer questions (adjust accordingly) for auto-restart loop:

```
export HUGGINGFACE_ACCESS_TOKEN="None"
export MODEL_NAME="Gensyn/Qwen2.5-1.5B-Instruct"
export PRG_GAME=true
```

## RL Swarm

RL Swarm is a peer-to-peer system for reinforcement learning. It allows you to train models collaboratively with others in the swarm, leveraging their collective intelligence. It is open source and permissionless, meaning you can run it on a consumer laptop at home or on a powerful GPU in the cloud. You can also connect your model to the Gensyn Testnet to receive an on-chain identity that tracks your progress over time.

Currently, we are running the [reasoning-gym](https://github.com/open-thought/reasoning-gym/tree/main) swarm on the Testnet. This swarm is designed to train models to solve a diverse set of reasoning tasks using the reasoning-gym dataset. The current list of default models includes:

Models:
   - Gensyn/Qwen2.5-0.5B-Instruct
   - Qwen/Qwen3-0.6B
   - nvidia/AceInstruct-1.5B
   - dnotitia/Smoothie-Qwen3-1.7B
   - Gensyn/Qwen2.5-1.5B-Instruct

This iteration of rl-swarm is powered by the [GenRL](https://github.com/gensyn-ai/genrl) library.  It is a fully composable framework for decentralized reinforcement learning which enables users to create and customize their own swarms for reinforcement learning with multi-agent multi-stage environments.

## Requirements

Your hardware requirements will vary depending on a number of factors including model size and the accelerator platform you use.  Users running large NVIDIA GPU will be assigned a model from the large model pool, while users running less powerful hardware will be assigned a model from the small model pool. This design decision is intended to allow users to advance at a similar rate regardless of the hardware they use, maximizing their utility to the swarm.      

**Supported Hardware**

- arm64 or x86 CPU with minimum 32gb ram (note that if you run other applications during training it might crash training).


OR

- CUDA devices (officially supported):
    - RTX 3090
    - RTX 4090
    - RTX 5090
    - A100
    - H100


With either configuration, you will need Python >=3.10 (for Mac, you will likely need to upgrade).

## ⚠️ Please read before continuing ⚠️

This software is **experimental** and provided as-is for users who are interested in using (or helping to develop) an early version of the Gensyn Protocol for training models.

If you care about on-chain participation, you **must** read the [Identity Management](#identity-management) section below.

If you encounter issues, please first check [Troubleshooting](#troubleshooting). If you cannot find a solution there, please check if there is an open (or closed) [Issue](../../issues). If there is no relevant issue, please file one and include 1) all relevant [logs](#troubleshooting), 2) information about your device (e.g. which GPU, if relevant), and 3) your operating system information.

## Instructions

### Run the Swarm

The easiest way to run RL Swarm is using Docker. This ensures a consistent setup across all operating systems with minimal dependencies.

#### 1. Clone this repo

```
git clone https://github.com/oxngon/rl-swarm && cd rl-swarm
```

### Experimental (advanced) mode

If you want to experiment with the [GenRL](https://github.com/gensyn-ai/genrl) library or the[configurable parameters](https://github.com/gensyn-ai/rl-swarm/blob/main/rgym_exp/config/rg-swarm.yaml ), we recommend you run RL Swarm via shell script:
```sh
python3 -m venv .venv
source .venv/bin/activate
./run_rl_swarm.sh
```  
To learn more about experimental mode, check out our [getting started guide](https://github.com/gensyn-ai/genrl/blob/main/getting_started.ipynb).

### Login

1. A browser window will pop open (you'll need to manually navigate to http://localhost:3000/ if you're on a VM).
2. Click 'login'.
3. Login with your preferred method.

### Huggingface (recommend 'NONE')

If you would like to upload your model to Hugging Face, enter your Hugging Face access token when prompted. You can generate one from your Hugging Face account, under [Access Tokens](https://huggingface.co/docs/hub/en/security-tokens).

### Initial peering and training

From this stage onward your device will begin training. You should see your peer register and vote on-chain [here](https://gensyn-testnet.explorer.alchemy.com/address/0xFaD7C5e93f28257429569B854151A1B8DCD404c2?tab=logs).

You can also track your training progress in real time:
- On The RL-Swarm Dashboard: [dashboard.gensyn.ai](https://dashboard.gensyn.ai)
