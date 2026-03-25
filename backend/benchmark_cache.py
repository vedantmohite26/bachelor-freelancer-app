import requests
import time
import json

URL = "http://localhost:8000/finance-ai"

def benchmark():
    payload = {
        "message": "Can I buy coffee?",
        "expenses": "System Date/Time: 2023-10-27 10:15\nUser Data:\nBudget: 5000\nSpent: 0",
        "history": [],
        "app_data": "User Profile: Test"
    }

    print("--- Starting Benchmark ---")

    # 1. Cold Request (Cache Miss)
    start = time.time()
    res1 = requests.post(URL, json=payload)
    end = time.time()
    print(f"Cold Request Latency: {(end - start) * 1000:.2f}ms")

    # 2. Warm Request (Cache Hit - Identical)
    start = time.time()
    res2 = requests.post(URL, json=payload)
    end = time.time()
    print(f"Warm Request (Identical) Latency: {(end - start) * 1000:.2f}ms")

    # 3. Warm Request (Cache Hit - Normalized Timestamp)
    payload_normalized = payload.copy()
    payload_normalized["expenses"] = "System Date/Time: 2023-10-27 10:45\nUser Data:\nBudget: 5000\nSpent: 0"

    start = time.time()
    res3 = requests.post(URL, json=payload_normalized)
    end = time.time()
    print(f"Warm Request (Normalized) Latency: {(end - start) * 1000:.2f}ms")

    # 4. Different Request (Cache Miss)
    payload_diff = payload.copy()
    payload_diff["message"] = "Can I buy a car?"

    start = time.time()
    res4 = requests.post(URL, json=payload_diff)
    end = time.time()
    print(f"Different Request Latency: {(end - start) * 1000:.2f}ms")

if __name__ == "__main__":
    benchmark()
