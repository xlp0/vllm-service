#!/usr/bin/env python3
"""
vLLM Service Verification Script
Tests OpenAI-compatible endpoints: /v1/models and /v1/chat/completions
"""

import urllib.request
import json
import sys
import time

BASE_URL = "http://127.0.0.1:8000"

def test_health():
    print("1. Checking server health status...")
    try:
        req = urllib.request.Request(f"{BASE_URL}/health")
        with urllib.request.urlopen(req, timeout=5) as response:
            if response.status == 200:
                print("   [SUCCESS] vLLM server is healthy!")
                return True
    except Exception as e:
        print(f"   [ERROR] Health check failed: {e}")
        return False

def test_models():
    print("\n2. Fetching available models (/v1/models)...")
    try:
        req = urllib.request.Request(f"{BASE_URL}/v1/models")
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            models = [m["id"] for m in data.get("data", [])]
            print(f"   [SUCCESS] Loaded model(s): {models}")
            return models[0] if models else None
    except Exception as e:
        print(f"   [ERROR] Failed to list models: {e}")
        return None

def test_chat_completion(model_id):
    print(f"\n3. Testing Chat Completion with model '{model_id}'...")
    payload = {
        "model": model_id,
        "messages": [
            {"role": "user", "content": "Explain key features of vLLM in 2 concise sentences."}
        ],
        "max_tokens": 150,
        "temperature": 0.7
    }
    
    req = urllib.request.Request(
        f"{BASE_URL}/v1/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    
    try:
        start_time = time.time()
        with urllib.request.urlopen(req, timeout=30) as response:
            res_data = json.loads(response.read().decode())
            elapsed = time.time() - start_time
            content = res_data["choices"][0]["message"]["content"]
            print(f"   [SUCCESS] Response received in {elapsed:.2f}s:")
            print("-" * 50)
            print(content.strip())
            print("-" * 50)
            return True
    except Exception as e:
        print(f"   [ERROR] Chat completion failed: {e}")
        return False

def main():
    print("==========================================")
    print("   vLLM Docker Service API Test")
    print("==========================================")
    
    if not test_health():
        print("\nMake sure vLLM is running via Docker:")
        print("  docker compose up -d (or sudo docker compose up -d)")
        sys.exit(1)
        
    model_id = test_models()
    if not model_id:
        print("\n[ERROR] No models loaded.")
        sys.exit(1)
        
    if test_chat_completion(model_id):
        print("\n🎉 All tests passed successfully!")
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
