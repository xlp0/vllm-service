# 🏗️ Architectural Findings & Stack Overview

This document summarizes the primary architectural paradigms, deployment modes, and serving capabilities outlined in the project documentation ([README.md](file:///home/pc/Documents/AIProjects/vllm-service/README.md)).

---

## 📌 Executive Summary

The **vLLM Service & Open WebUI Stack** is an enterprise-grade LLM inference and web chat environment. It is designed to host state-of-the-art open models (e.g., Qwen 2.5, Qwen 3.6 FP8, KAT-Coder) across single-GPU developer systems and high-throughput multi-node GPU clusters (DGX Spark).

---

## 🚀 Deployment Paradigms

### Mode 1: Single-Node Deployment (Docker Compose)
- **Target Workloads**: Development, prototyping, single-GPU models (e.g., Qwen 2.5-0.5B, Qwen 2.5-7B, KAT-Coder-AWQ).
- **Core Components**:
  1. **vLLM Server (`vllm-server`)**: Serves an OpenAI-compatible REST API on port `8000`.
  2. **Open WebUI (`open-webui`)**: Web interface hosted on port `3000` connected directly to the vLLM engine.
  3. **LiteLLM Router (`litellm`)**: Intelligent API proxy hosted on port `4000` handling model routing, load balancing, and fallback execution.

### Mode 2: Multi-Node Cluster Deployment (`spark-vllm-docker`)
- **Target Workloads**: High-concurrency production serving of massive LLMs (e.g., `Qwen/Qwen3.6-35B-A3B-FP8`).
- **Infrastructure**:
  - 2-node DGX Spark cluster (`asus-1` head node + `msi-1` worker node).
  - High-speed 200Gbps RoCE/InfiniBand inter-node connection.
  - Native PyTorch Distributed backend (`--nnodes 2`, NCCL over InfiniBand) without Ray overhead.
- **Orchestration**: Managed via the recipe system in `/home/vllm/spark-vllm-docker/`.

---

## 🛠️ Model Serving Architecture & Recipes

| Recipe / Model Name | Base Model | Quantization | Features & Key Optimization Flags |
| --- | --- | --- | --- |
| `qwen3.6-35b-a3b-fp8` | `Qwen/Qwen3.6-35B-A3B-FP8` | FP8 | FlashInfer attention, DeepGEMM MoE, FP8 KV cache, 262K context, Reasoning parser (`--reasoning-parser qwen3`) |
| `Qwen/Qwen2.5-7B-Instruct` | `Qwen/Qwen2.5-7B-Instruct` | Unquantized / BF16 | Native 32k/128k context, FlashAttention-2, Pythonic tool calling |
| `Qwen/Qwen2.5-0.5B-Instruct` | `Qwen/Qwen2.5-0.5B-Instruct` | Unquantized / BF16 | Lightweight testing model, 32k context, <1GB VRAM footprint |

---

## 🌐 Open WebUI Integration

- Connected via `http://vllm:8000/v1` inside Docker Compose or `http://172.18.0.1:8000/v1` standalone.
- Integrated DuckDuckGo search integration for RAG web browsing.
- SQLite database persistence at `open-webui-data` volume (`/app/backend/data/webui.db`).
