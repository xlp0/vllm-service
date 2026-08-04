# 🚀 vLLM Docker Service & Open WebUI Stack

A high-performance, production-ready LLM serving stack powered by **vLLM** and **Open WebUI**, fully orchestrated with **Docker Compose** and **NVIDIA GPU acceleration**.

---

## 🏗️ Architecture & Features

This stack provides an end-to-end local LLM inference environment:

- **vLLM Engine (`vllm-server`)**:
  - Serves high-throughput LLM inference with PagedAttention and eager execution mode.
  - Exposes standard OpenAI-compatible API endpoints (`/v1/chat/completions`, `/v1/models`).
  - Supports single-GPU and multi-GPU tensor parallelism (`TENSOR_PARALLEL_SIZE`).
  - Automatic model downloading and persistent caching from Hugging Face.
- **Open WebUI (`open-webui`)**:
  - Web-based chat interface connected directly to the vLLM backend.
  - Rich chat history, custom model prompts, and user-friendly interface.
- **Automated Testing (`test_service.py`)**:
  - Pre-built Python script to verify health status, model discovery, and chat completion performance.

---

## 📋 Prerequisites

1. **NVIDIA GPU & Drivers** (NVIDIA Container Toolkit installed).
2. **Docker & Docker Compose** (Plugin v2+).
3. **Docker Permissions** (Ensure user is in the `docker` group):
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```
   *(Or run docker compose commands with `sudo`).*

---

## 🚀 Quick Start

### 1. Configure Environment
Copy the example environment file:
```bash
cp .env.example .env
```

Customize `.env` according to your hardware setup (see [Environment Configuration](#-environment-configuration) below).

### 2. Launch the Stack
Start both vLLM serving engine and Open WebUI in detached mode:
```bash
docker compose up -d
```

### 3. Monitor Engine Initialization
vLLM will download model weights on initial startup and allocate CUDA memory pools:
```bash
docker compose logs -f vllm
```

### 4. Access Open WebUI
Once initialization completes, open your browser and navigate to:
👉 **[http://localhost:3000](http://localhost:3000)**

### 5. Run API Verification
Execute the automated test script to verify API health and model completion:
```bash
python3 test_service.py
```

---

## ⚙️ Environment Configuration

All stack options are configured via `.env`:

| Parameter | Default Value | Description |
| --- | --- | --- |
| `MODEL_NAME` | `Qwen/Qwen2.5-7B-Instruct` | Hugging Face repository ID or path to model |
| `HF_TOKEN` | *(Empty)* | Hugging Face Access Token for gated models (e.g., Llama 3) |
| `GPU_MEMORY_UTILIZATION` | `0.90` | Fraction of GPU VRAM reserved for KV cache (0.0 to 1.0) |
| `MAX_MODEL_LEN` | `4096` | Context window length cap in tokens |
| `TENSOR_PARALLEL_SIZE` | `1` | Number of GPUs to split model across (multi-GPU setup) |
| `PORT` | `8000` | Host port for vLLM OpenAI-compatible REST API |
| `OPEN_WEBUI_PORT` | `3000` | Host port for Open WebUI browser interface |
| `HF_CACHE_DIR` | `~/.cache/huggingface` | Host directory to store downloaded model weights |

---

## 💡 Usage & Integration Examples

### 1. Open WebUI (Browser)
Navigate to `http://localhost:3000` in your web browser. Authentication is disabled by default (`WEBUI_AUTH=false`) for seamless local development.

---

### 2. OpenAI-Compatible REST API (cURL)

#### Check Health Endpoint
```bash
curl http://localhost:8000/health
```

#### List Available Models
```bash
curl http://localhost:8000/v1/models
```

#### Chat Completions Request
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen2.5-7B-Instruct",
    "messages": [
      {"role": "user", "content": "Explain quantum computing in two sentences."}
    ],
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

---

### 3. Python OpenAI SDK Integration
Install official SDK: `pip install openai`

```python
from openai import OpenAI

# Connect to vLLM server
client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="EMPTY"  # vLLM engine does not require API key by default
)

response = client.chat.completions.create(
    model="Qwen/Qwen2.5-7B-Instruct",
    messages=[
        {"role": "user", "content": "What are the core features of vLLM?"}
    ],
    max_tokens=150,
    temperature=0.7
)

print(response.choices[0].message.content)
```

---

## 🔐 Gated Models (e.g., Llama 3 / 3.1)

To serve gated or private models:

1. Request repository access on Hugging Face (e.g. `meta-llama/Meta-Llama-3.1-8B-Instruct`).
2. Generate a Hugging Face Access Token (`read` scope) at [hf.co/settings/tokens](https://huggingface.co/settings/tokens).
3. Set token and model name in `.env`:
   ```env
   MODEL_NAME=meta-llama/Meta-Llama-3.1-8B-Instruct
   HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
4. Restart service:
   ```bash
   docker compose down && docker compose up -d
   ```

---

## 🛠️ Service Management Commands

| Action | Command |
| --- | --- |
| Start all services | `docker compose up -d` |
| View vLLM logs | `docker compose logs -f vllm` |
| View Open WebUI logs | `docker compose logs -f open-webui` |
| View all logs | `docker compose logs -f` |
| Check vLLM health | `curl http://localhost:8000/health` |
| Stop all services | `docker compose down` |
| Restart services | `docker compose restart` |

---

## ⚡ Multi-GPU & Performance Tuning

- **Multi-GPU / Tensor Parallelism**:
  Set `TENSOR_PARALLEL_SIZE` to match your GPU count in `.env` (e.g. `TENSOR_PARALLEL_SIZE=2` for 2 GPUs).
- **GPU Memory Reservation**:
  Adjust `GPU_MEMORY_UTILIZATION` (default `0.90`). If encountering Out-Of-Memory (OOM) errors due to concurrent GPU tasks, reduce to `0.80` or `0.85`.
- **Context Length Cap**:
  Adjust `MAX_MODEL_LEN` to fit your model and VRAM budget (e.g., `4096`, `8192`, `16384`).

---

## 📄 License & Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
