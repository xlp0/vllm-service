# ⚠️ Technical Observations & Configuration Gotchas

This document records critical empirical observations, runtime pitfalls, and configuration gotchas discovered during the setup and operation of the **vLLM + LiteLLM + Open WebUI** stack.

---

## 1. 📁 Hugging Face Cache Path Expansion (`~` vs. Absolute Path)

> [!WARNING]
> **Issue**: Docker Compose **does NOT expand `~`** in `.env` variables or volume definitions.

- **Observed Behavior**:
  Setting `HF_CACHE_DIR=~/.cache/huggingface` in `.env` causes Docker Compose to mount a literal directory path (`./~/.cache/huggingface`) relative to the project directory into `/root/.cache/huggingface`.
- **Impact**:
  vLLM sees an empty cache inside the container and attempts to redownload multi-gigabyte models over the network on every restart, leading to long delays and `Connection reset by peer` errors.
- **Fix**:
  Always use absolute paths in [.env](file:///home/pc/Documents/AIProjects/vllm-service/.env) and [docker-compose.yml](file:///home/pc/Documents/AIProjects/vllm-service/docker-compose.yml):
  ```env
  HF_CACHE_DIR=/home/pc/.cache/huggingface
  ```

---

## 2. ⚡ Open WebUI RAG Embedding Engine Failure

> [!CAUTION]
> **Issue**: Setting `RAG_EMBEDDING_ENGINE=""` (an empty string) in `docker-compose.yml` causes Open WebUI to crash during startup.

- **Observed Behavior**:
  FastAPI lifespan initialization fails with `ValueError: Unknown embedding engine: ""` and Open WebUI terminates during database seeding.
- **Impact**:
  The Open WebUI container enters a crash loop or returns `500 Internal Error`.
- **Database Gotcha**:
  Open WebUI caches configuration inside its SQLite database (`/app/backend/data/webui.db`). If `RAG_EMBEDDING_ENGINE=""` was once set, the database persists the empty string even after `docker-compose.yml` is edited.
- **Fix**:
  Omit `RAG_EMBEDDING_ENGINE` or set `RAG_EMBEDDING_ENGINE=sentence_transformers`, and reset the database volume if corrupted:
  ```bash
  sudo docker compose down
  sudo docker volume rm vllm-service_open-webui-data
  sudo docker compose up -d
  ```

---

## 3. 🛠️ Auto Tool Choice & Function Calling Requirements

> [!IMPORTANT]
> **Issue**: Requests specifying `"tool_choice": "auto"` fail with `"auto" tool choice requires --enable-auto-tool-choice and --tool-call-parser to be set`.

- **Observed Behavior**:
  vLLM v0.26.0 disables function calling and auto tool choice by default. Sending tool schemas from Open WebUI or LiteLLM without vLLM flags causes immediate HTTP 400 rejection.
- **Fix**:
  Include the following arguments in [docker-compose.yml](file:///home/pc/Documents/AIProjects/vllm-service/docker-compose.yml):
  ```yaml
  command:
    - "--enable-auto-tool-choice"
    - "--tool-call-parser"
    - "pythonic" # or qwen_agent / llama3_json depending on model
  ```

---

## 4. 📐 Context Length Limits (`MAX_MODEL_LEN`)

> [!WARNING]
> **Issue**: Setting `MAX_MODEL_LEN=4096` causes prompt rejection on long conversations or tool payloads.

- **Observed Behavior**:
  Requests exceeding 4096 tokens fail with `This model's maximum context length is 4096 tokens. However, you requested 0 output tokens and your prompt contains at least 4097 input tokens`.
- **Fix**:
  Increase `MAX_MODEL_LEN` in [.env](file:///home/pc/Documents/AIProjects/vllm-service/.env) to **`32768`** (32k tokens) or match the model's maximum context limit.

---

## 5. 🌐 IPv6 `localhost` Socket Resets in Python `urllib`

> [!NOTE]
> **Issue**: Python's `urllib.request` against `http://localhost:8000` can fail with `[Errno 104] Connection reset by peer`.

- **Observed Behavior**:
  Linux system DNS resolves `localhost` to IPv6 `::1` first. If Docker binds port 8000 on IPv4 (`0.0.0.0:8000`), Python attempts IPv6 first, receives connection reset, and aborts.
- **Fix**:
  Use `http://127.0.0.1:8000` explicitly in python verification scripts ([test_service.py](file:///home/pc/Documents/AIProjects/vllm-service/test_service.py)).

---

## 6. 🐳 Docker Compose Healthcheck Binary

> [!TIP]
> **Issue**: `vllm/vllm-openai:latest` image does NOT contain the `curl` binary.

- **Observed Behavior**:
  Healthchecks using `curl -f http://localhost:8000/health` report `command not found` inside container execution.
- **Fix**:
  Use Python's built-in `urllib` module for container healthchecks:
  ```yaml
  healthcheck:
    test: ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost:8000/health')\" || exit 1"]
  ```
