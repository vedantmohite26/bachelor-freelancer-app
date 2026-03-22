import requests
import time
import json

URL = "http://127.0.0.1:8004/finance-ai"

def benchmark():
    payload = {
        "message": "Can I buy a ₹300 coffee?",
        "expenses": "System Date/Time: 2024-03-20 14:35\nUser Data:\nBudget: 5000\nSpent: 0",
        "app_data": "User Profile: Test",
        "history": []
    }

    print("\n--- Benchmarking AI Cache ---")

    # 1. Cold Start
    start = time.time()
    r1 = requests.post(URL, json=payload)
    end = time.time()
    cold_time = (end - start) * 1000
    print(f"1. Cold Start: {cold_time:.2f}ms")

    # 2. Identical Request (Cached)
    start = time.time()
    r2 = requests.post(URL, json=payload)
    end = time.time()
    cached_time = (end - start) * 1000
    print(f"2. Identical Request (Cache Hit): {cached_time:.2f}ms")

    # 3. Normalized Request (Within same hour)
    payload_normalized = payload.copy()
    payload_normalized["expenses"] = "System Date/Time: 2024-03-20 14:45\nUser Data:\nBudget: 5000\nSpent: 0"

    start = time.time()
    r3 = requests.post(URL, json=payload_normalized)
    end = time.time()
    norm_time = (end - start) * 1000
    print(f"3. Normalized Request (Cache Hit): {norm_time:.2f}ms")

    # 4. Different Request (Cache Miss)
    payload_diff = payload.copy()
    payload_diff["message"] = "Can I buy a ₹5000 laptop?"

    start = time.time()
    r4 = requests.post(URL, json=payload_diff)
    end = time.time()
    diff_time = (end - start) * 1000
    print(f"4. Different Request (Cache Miss): {diff_time:.2f}ms")

    if cold_time > 0:
        speedup = cold_time / cached_time if cached_time > 0 else 0
        print(f"\n⚡ Performance Gain: {speedup:.1f}x faster for cache hits.")

if __name__ == "__main__":
    try:
        benchmark()
    except Exception as e:
        print(f"Benchmark failed: {e}")
        print("Ensure the backend is running on port 8004.")
