import requests
import time
import json
import subprocess
import os
import signal

def run_benchmark():
    url = "http://127.0.0.1:8000/finance-ai"
    payload = {
        "message": "Can I buy a ₹300 coffee?",
        "expenses": "System Date/Time: 2023-10-27 10:00\nUser Data:\nBudget: 5000\nSpent: 0",
        "app_data": "User Profile: TestUser",
        "history": []
    }

    print("Starting benchmark...")

    # 1. Uncached request
    start_time = time.time()
    response1 = requests.post(url, json=payload)
    duration1 = time.time() - start_time
    print(f"Request 1 (Uncached/Mock): {duration1:.4f}s")
    print(f"Response 1: {response1.text[:50]}...")

    # 2. Cached request (identical payload)
    start_time = time.time()
    response2 = requests.post(url, json=payload)
    duration2 = time.time() - start_time
    print(f"Request 2 (Cached): {duration2:.4f}s")
    print(f"Response 2: {response2.text[:50]}...")

    # 3. Slightly different payload (should miss cache)
    payload["message"] = "Can I buy a ₹301 coffee?"
    start_time = time.time()
    response3 = requests.post(url, json=payload)
    duration3 = time.time() - start_time
    print(f"Request 3 (Cache Miss): {duration3:.4f}s")

    if duration2 < duration1:
        improvement = (duration1 - duration2) / duration1 * 100
        print(f"\n✅ Cache Hit Improvement: {improvement:.2f}% faster")
    else:
        print("\n❌ No improvement detected.")

if __name__ == "__main__":
    # Start the server in the background
    print("Starting backend server...")
    # Kill any process on port 8000
    os.system("kill $(lsof -t -i :8000) 2>/dev/null || true")

    process = subprocess.Popen(
        ["uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000"],
        cwd="backend",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Wait for server to start
    time.sleep(3)

    try:
        run_benchmark()
    finally:
        print("Stopping server...")
        process.terminate()
        process.wait()
