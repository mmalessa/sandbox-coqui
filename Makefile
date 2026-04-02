DC = docker compose
APP = coqui-tts

.DEFAULT_GOAL      = help

.PHONY: help
help:
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

### DEV
.PHONY: up
up: ## Start the project docker containers
	@$(DC) up -d

.PHONY: down
down: ## Down the docker containers
	@$(DC) down --timeout 25

.PHONY: build
build:
	@$(DC) build

.PHONY: sh
sh:
	@$(DC) exec -it ${APP} bash

.PHONY: logs
logs:
	@$(DC) logs -f ${APP}

.PHONY: nv-check
nv-check: ## Check if nvidia-container-toolkit is installed
	@if dpkg -s nvidia-container-toolkit > /dev/null 2>&1; then \
		echo "nvidia-container-toolkit is installed"; \
	else \
		echo "nvidia-container-toolkit is NOT installed. Run: make nv-prepare"; \
		exit 1; \
	fi

.PHONY: nv-prepare
nv-prepare: ## Install nvidia-container-toolkit and configure Docker runtime
	sudo apt install -y wget
	wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
	sudo dpkg -i cuda-keyring_1.1-1_all.deb
	sudo apt update
	sudo apt install -y nvidia-container-toolkit
	sudo nvidia-ctk runtime configure --runtime=docker
	echo 'Now restart docker: sudo systemctl restart docker'

.PHONY: tts-speakers
tts-speakers:
	@$(DC) exec ${APP} tts --model_name tts_models/multilingual/multi-dataset/xtts_v2 --list_speaker_idxs

.PHONY: tts-talk
TEXT := $(shell cat ./samples/input.txt)
tts-talk:
	@$(DC) exec ${APP} tts \
		--model_name tts_models/multilingual/multi-dataset/xtts_v2 \
		--language_idx pl \
		--speaker_idx "Filip Traverse" \
		--out_path /samples/test.wav \
		--text "$(TEXT)"
