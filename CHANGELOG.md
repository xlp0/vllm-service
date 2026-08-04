# Changelog

All notable changes to the **vLLM Service Stack** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-08-04

### Added
- **Open WebUI Frontend Integration**: Integrated `open-webui` container into `docker-compose.yml` mapped to `OPEN_WEBUI_PORT` (default `3000`) for out-of-the-box browser chat UI.
- **Multi-GPU / Tensor Parallelism Support**: Added `TENSOR_PARALLEL_SIZE` environment variable configuration in `docker-compose.yml` and `.env.example`.
- **Repository Security & Setup**: Added `.gitignore` to ignore sensitive credentials (`.env`) and local cache/data directories (`open-webui-data/`, `__pycache__/`).
- **Enhanced Documentation**: Created `CHANGELOG.md` and expanded `README.md` with complete stack architecture, Open WebUI usage, full environment reference table, and multi-GPU tuning options.

### Changed
- Updated `.env.example` to align with all `.env` options including `OPEN_WEBUI_PORT`.
- Standardized container environment variable naming and default fallback values in `docker-compose.yml`.

---

## [1.0.0] - 2026-08-03

### Added
- **vLLM Docker Stack**: Docker Compose configuration running `vllm/vllm-openai:latest` with NVIDIA GPU acceleration (`capabilities: [gpu]`) and host IPC.
- **Configurable Environment Setup**: Added `.env` template supporting Hugging Face model selection (`MODEL_NAME`), context size (`MAX_MODEL_LEN`), memory reservation (`GPU_MEMORY_UTILIZATION`), and authentication tokens (`HF_TOKEN`).
- **Service Verification Tooling**: Created `test_service.py` to validate API health (`/health`), model discovery (`/v1/models`), and LLM chat inference (`/v1/chat/completions`).
- **Initial Documentation**: Created standard `README.md` with REST API cURL and Python OpenAI SDK code snippets.
