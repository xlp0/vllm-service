# 💡 Critical Suggestions & Best Practices

This document provides actionable engineering recommendations to improve performance, reliability, and maintainability of the **vLLM + LiteLLM + Open WebUI** stack.

---

## 🎯 1. High-Availability LiteLLM Routing & Model Fallbacks

### Problem
When single-node vLLM engines restart or swap models, LiteLLM throws `litellm.InternalServerError: Connection error.. Available Model Group Fallbacks=None` if no fallback targets are configured.

### Recommendation
Maintain a multi-tier fallback hierarchy in [litellm-config.yaml](file:///home/pc/Documents/AIProjects/vllm-service/litellm-config.yaml):
```yaml
model_list:
  - model_name: Qwen/Qwen2.5-0.5B-Instruct
    litellm_params:
      model: openai/Qwen/Qwen2.5-0.5B-Instruct
      api_base: http://127.0.0.1:8000/v1
      api_key: EMPTY

  - model_name: Qwen/Qwen2.5-7B-Instruct
    litellm_params:
      model: openai/Qwen/Qwen2.5-7B-Instruct
      api_base: http://127.0.0.1:8000/v1
      api_key: EMPTY

  - model_name: Qwen/Qwen3.6-35B-A3B-FP8
    litellm_params:
      model: openai/Qwen/Qwen3.6-35B-A3B-FP8
      api_base: http://127.0.0.1:8000/v1
      api_key: EMPTY

router_settings:
  fallbacks:
    - Qwen/Qwen2.5-0.5B-Instruct: ["Qwen/Qwen2.5-7B-Instruct", "Qwen/Qwen3.6-35B-A3B-FP8"]
```

---

## ⚡ 2. Memory & KV Cache Tuning Guidelines

### Problem
Over-allocating `gpu_memory_utilization` (e.g. `0.90` on 121 GiB VRAM GPUs) can cause OOM crashes during FlashAttention/FlashInfer kernel warmup or PyTorch allocation.

### Recommendation
1. Set `GPU_MEMORY_UTILIZATION=0.65` or `0.80` for single-GPU local instances.
2. For high-concurrency 32k context serving, explicit `--kv-cache-memory` allocation is recommended:
   ```bash
   --kv-cache-memory 83007025869
   ```
3. Enable `--enable-prefix-caching` and `--enable-chunked-prefill` for multi-turn chats to drastically reduce time-to-first-token (TTFT).

---

## 🔒 3. Environment Security & Credentials Hygiene

### Recommendation
1. Move sensitive tokens out of `.env` files committed to version control.
2. Ensure `.env` is listed in `.gitignore`.
3. Rotate Hugging Face User Access Tokens (`HF_TOKEN`) regularly.

---

## 📦 4. Pre-caching Hugging Face Models

### Recommendation
Before deploying new models to single-node or cluster deployments, pre-download weights to `/home/pc/.cache/huggingface` via `huggingface-cli`:
```bash
python3 -m pip install huggingface_hub[cli]
huggingface-cli download Qwen/Qwen2.5-7B-Instruct --local-dir /home/pc/.cache/huggingface/hub/models--Qwen--Qwen2.5-7B-Instruct
```
This guarantees zero-downtime container starts without network bottleneck dependencies.

---

## 🧪 5. Automated CI/CD Health & Service Checks

### Recommendation
Incorporate [test_service.py](file:///home/pc/Documents/AIProjects/vllm-service/test_service.py) into startup verification scripts or GitHub Actions workflows:
```bash
python3 test_service.py || (echo "vLLM service verification failed" && exit 1)
```
