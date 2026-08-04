# 🚀 vLLM Service & Open WebUI Stack

A high-performance LLM serving stack powered by **vLLM** and **Open WebUI**, supporting both single-node Docker Compose deployment and **multi-node DGX Spark clusters** via `spark-vllm-docker`.

---

## 📚 Documentation & Technical Guides

Detailed architectural analysis, empirical observations, gotchas, and critical engineering suggestions are organized in the [`docs/`](file:///home/pc/Documents/AIProjects/vllm-service/docs) directory:

- 🏗️ **[Architectural Findings & Stack Overview](file:///home/pc/Documents/AIProjects/vllm-service/docs/architectural_findings.md)**: Deep dive into deployment modes, cluster vs single-node paradigms, and model specs.
- ⚠️ **[Technical Observations & Configuration Gotchas](file:///home/pc/Documents/AIProjects/vllm-service/docs/observations_and_gotchas.md)**: Full breakdown of resolved issues (HF cache `~` expansion, Open WebUI RAG engine crashes, auto tool choice flags, 32k context expansion, IPv6 socket resets).
- 💡 **[Critical Suggestions & Best Practices](file:///home/pc/Documents/AIProjects/vllm-service/docs/critical_suggestions.md)**: Actionable recommendations for LiteLLM fallback routing, memory KV cache optimization, and CI/CD service testing.

---

## 🏗️ Architecture

Two deployment modes are supported:

### Mode 1: Single-Node (Docker Compose)
- **vLLM Engine (`vllm-server`)**: Serves OpenAI-compatible API with tensor parallelism on a single node.
- **Open WebUI (`open-webui`)**: Web chat frontend connected to vLLM.
- Use for development, testing, or single-GPU models.

### Mode 2: Multi-Node Cluster (spark-vllm-docker) — **Recommended for large models**
- **2-node DGX Spark cluster** (asus-1 head + msi-1 worker) connected via 200Gbps RoCE/InfiniBand.
- Uses the **recipe system** in `/home/vllm/spark-vllm-docker/` for proper cluster orchestration.
- Handles container launch, model distribution, chat template mods, and optimized vLLM args.
- Uses PyTorch distributed (`--nnodes 2`) with NCCL over InfiniBand, not Ray.
- Currently serving: **Qwen/Qwen3.6-35B-A3B-FP8** (FP8 quantized, 262K context, TP=2).

---

## 📋 Prerequisites

1. **NVIDIA GPU & Drivers** (NVIDIA Container Toolkit installed).
2. **Docker & Docker Compose** (Plugin v2+).
3. **Docker Permissions** (user in `docker` group, or use `sudo`).
4. **For multi-node**: `spark-vllm-docker` repo set up at `/home/vllm/spark-vllm-docker/` with `.env` configured (cluster nodes, network interfaces).

---

## 🚀 Quick Start

### Mode 1: Single-Node (Docker Compose)

```bash
# Configure
cp .env.example .env
# Edit .env: set MODEL_NAME, TENSOR_PARALLEL_SIZE, etc.

# Launch
docker compose up -d

# Monitor
docker compose logs -f vllm

# Access WebUI at http://localhost:3000
```

### Mode 2: Multi-Node Cluster (spark-vllm-docker) — **Recommended**

```bash
# Start the 2-node cluster + serve Qwen3.6-35B-A3B-FP8
sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh qwen3.6-35b-a3b-fp8 --setup -d'

# Stop the cluster
sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./launch-cluster.sh stop'

# List available recipes
sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh --list'

# Dry run (see what would be executed)
sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh qwen3.6-35b-a3b-fp8 --setup --dry-run'
```

### CLI Testing

```bash
# Quick CLI test
bash test_cli.sh "What is the tallest mountain on Earth?"

# Or use curl directly
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3.6-35B-A3B-FP8",
    "messages": [{"role": "user", "content": "Explain quantum computing in two sentences."}],
    "max_tokens": 500,
    "temperature": 0.7
  }'
```

### Access Open WebUI

Open **[http://localhost:3000](http://localhost:3000)** in your browser.
- Default login: `admin@localhost` / `admin` (auto-created on first run).
- Select the model from the dropdown (e.g., `Qwen/Qwen3.6-35B-A3B-FP8`).
- Web search is enabled via DuckDuckGo (click "+" next to message box, toggle "Web Search").

---

## ⚙️ Environment Configuration (.env for Docker Compose mode)

| Parameter | Default Value | Description |
| --- | --- | --- |
| `MODEL_NAME` | `Qwen3.6-35B-A3B` | Hugging Face model ID |
| `HF_TOKEN` | *(Empty)* | Hugging Face Access Token for gated models |
| `GPU_MEMORY_UTILIZATION` | `0.90` | Fraction of GPU VRAM for KV cache (0.0 to 1.0) |
| `MAX_MODEL_LEN` | `4096` | Context window length cap in tokens |
| `TENSOR_PARALLEL_SIZE` | `2` | Number of GPUs to split model across |
| `PORT` | `8000` | Host port for vLLM API |
| `OPEN_WEBUI_PORT` | `3000` | Host port for Open WebUI |
| `HF_CACHE_DIR` | `~/.cache/huggingface` | Host directory for model weights |

---

## 🍳 Recipes (Multi-Node Cluster)

Recipes are YAML files in `/home/vllm/spark-vllm-docker/recipes/` that pre-configure model serving with optimized settings.

### Available Qwen3.6 Recipes

| Recipe | Model | Quantization | Notes |
| --- | --- | --- | --- |
| `qwen3.6-35b-a3b-fp8` | `Qwen/Qwen3.6-35B-A3B-FP8` | FP8 | **Recommended.** FlashInfer attention, DeepGEMM MoE, 262K context. |
| `qwen3.6-35b-a3b-fp8-dflash` | `Qwen/Qwen3.6-35B-A3B-FP8` | FP8 | Alternative FP8 loader. |
| `qwen3.6-35b-a3b-nvfp4` | `nvidia/Qwen3.6-35B-A3B-NVFP4` | NVFP4 | Marlin MoE backend, MTP speculative decoding. |
| `qwen3.6-35b-a3b-nvfp4-no-mtp` | `nvidia/Qwen3.6-35B-A3B-NVFP4` | NVFP4 | Same as above but without MTP. |

### Recipe Configuration (qwen3.6-35b-a3b-fp8)

The recipe automatically applies:
- **Chat template fix** (`mods/fix-qwen3.6-chat-template`)
- **FP8 KV cache** (`--kv-cache-dtype fp8`)
- **FlashInfer attention** (`--attention-backend flashinfer`)
- **DeepGEMM MoE backend** (auto-selected for FP8)
- **FastSafetensors loading** (`--load-format fastsafetensors`)
- **Reasoning parser** (`--reasoning-parser qwen3`) — separates thinking from answer
- **Tool call parser** (`--tool-call-parser qwen3_xml`)
- **Prefix caching** enabled
- **Max context**: 262,144 tokens
- **GPU memory utilization**: 0.8
- **Env**: `VLLM_MARLIN_USE_ATOMIC_ADD=1`

### Recipe CLI Options

```bash
./run-recipe.sh qwen3.6-35b-a3b-fp8 [OPTIONS]

# Common options:
--setup              # Full setup: build + download + run
--dry-run            # Show what would happen
-d, --daemon         # Run in background
--solo               # Single node (no cluster)
-n, --nodes IPS      # Comma-separated node IPs (first = head)
--port PORT          # Override port
--gpu-mem N          # Override GPU memory utilization
--tp N               # Override tensor parallelism
--max-model-len N    # Override max context length
-- ARGS...           # Pass extra args to vLLM
```

---

## 🌐 Open WebUI Setup

The Open WebUI container is configured to connect to vLLM via the Docker bridge IP:

```bash
# Run Open WebUI (standalone, not via docker compose)
docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 3000:8080 \
  -v open-webui-data:/app/backend/data \
  -e OPENAI_API_BASE_URL=http://172.18.0.1:8000/v1 \
  -e OPENAI_API_KEY=EMPTY \
  -e WEBUI_AUTH=false \
  -e OLLAMA_BASE_URL=disabled \
  -e ENABLE_RAG_WEB_SEARCH=true \
  -e WEB_SEARCH_ENGINE=duckduckgo \
  -e ENABLE_WEB_SEARCH=true \
  ghcr.io/open-webui/open-webui:main
```

### Important Notes
- **API URL**: Must use `http://172.18.0.1:8000/v1` (Docker bridge IP), not `http://vllm:8000/v1` (compose DNS name doesn't resolve when vLLM runs outside compose network).
- **DB persistence**: Open WebUI stores config in its SQLite DB. If the API URL is wrong in the DB, env vars won't override it. Fix via:
  ```bash
  docker exec open-webui python3 -c "
  import sqlite3, json
  conn = sqlite3.connect('/app/backend/data/webui.db')
  conn.execute(\"UPDATE config SET value = ? WHERE key = ?\", (json.dumps(['http://172.18.0.1:8000/v1']), 'openai.api_base_urls'))
  conn.commit()
  conn.close()
  "
  docker restart open-webui
  ```
- **Web search**: DuckDuckGo requires no API key. Toggle via the "+" icon next to the message box in the UI.
- **Fresh setup**: If models don't appear, wipe the volume and recreate:
  ```bash
  docker stop open-webui && docker rm open-webui
  docker volume rm open-webui-data
  # Then re-run the docker run command above
  ```

---

## 💡 Usage Examples

### cURL

```bash
# Check health
curl http://localhost:8000/health

# List models
curl http://localhost:8000/v1/models

# Chat completion
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3.6-35B-A3B-FP8",
    "messages": [{"role": "user", "content": "What is 2+2?"}],
    "max_tokens": 500,
    "temperature": 0.7
  }'
```

### Python OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="EMPTY"
)

response = client.chat.completions.create(
    model="Qwen/Qwen3.6-35B-A3B-FP8",
    messages=[{"role": "user", "content": "What are the core features of vLLM?"}],
    max_tokens=500,
    temperature=0.7
)

# The model separates reasoning from content
print("Reasoning:", response.choices[0].message.reasoning)
print("Answer:", response.choices[0].message.content)
```

### CLI Test Script

```bash
bash test_cli.sh "Your question here"
# Example:
bash test_cli.sh "What is the tallest mountain on Earth?"
```

---

## 🛠️ Service Management Commands

### Multi-Node Cluster (spark-vllm-docker)

| Action | Command |
| --- | --- |
| Start cluster + serve model | `sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh qwen3.6-35b-a3b-fp8 --setup -d'` |
| Stop cluster | `sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./launch-cluster.sh stop'` |
| List recipes | `sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh --list'` |
| Dry run | `sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh qwen3.6-35b-a3b-fp8 --setup --dry-run'` |
| Check vLLM health | `curl http://localhost:8000/health` |
| View vLLM logs | `sudo docker logs vllm_node --tail 30` |
| CLI test | `bash test_cli.sh "Your question"` |

### Single-Node (Docker Compose)

| Action | Command |
| --- | --- |
| Start all services | `docker compose up -d` |
| View vLLM logs | `docker compose logs -f vllm` |
| Stop all services | `docker compose down` |
| Restart services | `docker compose restart` |

### Open WebUI

| Action | Command |
| --- | --- |
| Restart WebUI | `docker restart open-webui` |
| View WebUI logs | `docker logs open-webui --tail 20` |
| Check model visibility | `curl -s http://localhost:8000/v1/models \| python3 -m json.tool` |

---

## ⚡ Performance Tuning

- **GPU Memory**: If encountering OOM errors, reduce `gpu_memory_utilization` (e.g., from 0.9 to 0.8 or 0.85). On GB10 GPUs with ~121 GiB total, 0.85 requests ~103 GiB which may exceed available free memory.
- **Context Length**: The FP8 recipe supports up to 262K tokens. For faster startup with less memory, override with `--max-model-len 8192`.
- **Tensor Parallelism**: TP=2 splits the model across both nodes. Each GB10 GPU has ~121 GiB VRAM.
- **Model loading**: The recipe uses `--load-format fastsafetensors` for faster weight loading.
- **MoE backend**: DeepGEMM is auto-selected for FP8 models on GB10. NVFP4 recipes use Marlin.

---

## 📥 Model Download & Distribution

### Download a model to the head node

```bash
# Using HF CLI (install: pip install huggingface_hub[cli])
hf download Qwen/Qwen3.6-35B-A3B-FP8 --local-dir ~/hf-models/Qwen3.6-35B-A3B-FP8

# Or use the spark-vllm-docker download script
sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh qwen3.6-35b-a3b-fp8 --download-only'
```

### Copy model to worker node

The fastest way is to tar and pipe over SSH via the RoCE link (~70 GB in ~2 minutes):

```bash
# From head node (as vllm user)
tar -cf - -C /home/vllm/.cache/huggingface/hub models--Qwen--Qwen3.6-35B-A3B-FP8 | \
  ssh vllm@10.0.0.2 "docker exec -i vllm_node tar -xf - -C /root/.cache/huggingface/hub/"
```

Alternatively, use the recipe's `--setup` flag which handles distribution automatically.

---

## 🔐 Gated Models

1. Request repository access on Hugging Face.
2. Generate a token at [hf.co/settings/tokens](https://huggingface.co/settings/tokens).
3. Set `HF_TOKEN` in `.env` (Docker Compose mode) or pass via `-e HF_TOKEN=hf_xxx` to the recipe.

---

## 📄 License & Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
