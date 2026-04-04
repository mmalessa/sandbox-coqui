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
tts-speakers: ## List available speakers via CLI (requires container with sleep infinity)
	@$(DC) exec ${APP} tts --model_name tts_models/multilingual/multi-dataset/xtts_v2 --list_speaker_idxs

.PHONY: tts-talk
TEXT := $(shell cat ./samples/input.txt)
tts-talk: ## Generate speech via CLI (requires container with sleep infinity)
	@$(DC) exec ${APP} tts \
		--model_name tts_models/multilingual/multi-dataset/xtts_v2 \
		--language_idx pl \
		--speaker_idx "Filip Traverse" \
		--out_path /samples/test.wav \
		--text "$(TEXT)"

### API
API_URL = http://localhost:5002/api

.PHONY: api-health
api-health: ## Check API health
	@curl -s $(API_URL)/health | python3 -m json.tool

.PHONY: api-speakers
api-speakers: ## List available speakers via API
	@curl -s $(API_URL)/speakers | python3 -m json.tool

.PHONY: api-languages
api-languages: ## List supported languages via API
	@curl -s $(API_URL)/languages | python3 -m json.tool

.PHONY: api-tts
TEXT := $(shell cat ./samples/input.txt)
api-tts: ## Generate speech via API (saves to samples/test.wav)
	@curl -s -X POST $(API_URL)/tts \
		-H "Content-Type: application/json" \
		-d '{"text": "$(TEXT)", "language": "pl", "speaker": "Filip Traverse"}' \
		--output ./samples/test.wav
	@echo "Saved to ./samples/test.wav"

.PHONY: api-docs
api-docs: ## Open interactive API docs in browser
	@xdg-open $(API_URL)/docs 2>/dev/null || open $(API_URL)/docs 2>/dev/null || echo "Open: http://localhost:5002/api/docs"
