#!/bin/bash
# Simple CLI test for 2-node vLLM service
# Usage: ./test_cli.sh "Your question here"
#
# Prerequisites: Cluster launched via recipe:
#   sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh qwen3.6-35b-a3b-fp8 --setup -d'
# Stop cluster:
#   sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./launch-cluster.sh stop'

VLLM_URL="http://localhost:8000"
MODEL="Qwen/Qwen3.6-35B-A3B-FP8"

# Check if vLLM is running
echo "Checking vLLM health..."
if ! curl -sf "${VLLM_URL}/health" >/dev/null 2>&1; then
    echo "ERROR: vLLM is not responding at ${VLLM_URL}"
    echo ""
    echo "To start the 2-node cluster:"
    echo "  sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./run-recipe.sh qwen3.6-35b-a3b-fp8 --setup -d'"
    echo ""
    echo "To stop:"
    echo "  sudo -u vllm bash -c 'cd /home/vllm/spark-vllm-docker && ./launch-cluster.sh stop'"
    exit 1
fi
echo "vLLM is healthy."

# List available models
echo ""
echo "Available models:"
curl -s "${VLLM_URL}/v1/models" | python3 -c "import sys,json; [print(f'  - {m[\"id\"]} (max_len: {m[\"max_model_len\"]})') for m in json.load(sys.stdin)['data']]"
echo ""

# If a question is provided, ask it
if [ -n "$1" ]; then
    QUERY="$1"
    echo "Asking: ${QUERY}"
    echo "---"
    curl -s "${VLLM_URL}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "$(python3 -c "
import json
print(json.dumps({
    'model': '${MODEL}',
    'messages': [{'role': 'user', 'content': '''${QUERY}'''}],
    'max_tokens': 1000,
    'temperature': 0.7
}))
")" | python3 -c "
import sys, json
d = json.load(sys.stdin)
m = d['choices'][0]['message']
if m.get('reasoning'):
    print('[Reasoning]', m['reasoning'][:500])
    print()
print('[Answer]', m.get('content') or '(empty)')
print()
u = d.get('usage', {})
print(f'Tokens: {u.get(\"prompt_tokens\",0)} prompt + {u.get(\"completion_tokens\",0)} completion = {u.get(\"total_tokens\",0)} total')
"
else
    echo "Usage: $0 \"Your question here\""
    echo "Example: $0 \"What is the tallest mountain on Earth?\""
fi
