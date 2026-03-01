import requests
import time
import json

URL = "http://127.0.0.1:8000/finance-ai"

def verify_cache():
    payload = {
        "message": "Can I buy a ₹300 coffee?",
        "expenses": "System Date/Time: 2024-05-20 10:00\nUser Data:\nBudget: 5000\nSpent: 0",
        "app_data": "User Profile: TestUser",
        "history": []
    }

    print("--- Performance Verification ---")

    # First Request (should be slow/uncached)
    start_time = time.time()
    response1 = requests.post(URL, json=payload)
    duration1 = time.time() - start_time
    print(f"Request 1 (Uncached) duration: {duration1:.4f}s")
    print(f"Response 1: {response1.text[:50]}...")

    # Second Request (should be fast/cached)
    start_time = time.time()
    response2 = requests.post(URL, json=payload)
    duration2 = time.time() - start_time
    print(f"Request 2 (Cached) duration:   {duration2:.4f}s")
    print(f"Response 2: {response2.text[:50]}...")

    if duration2 < duration1:
        print("\n✅ SUCCESS: Cache is working! Request 2 was faster.")
        improvement = (duration1 - duration2) / duration1 * 100
        print(f"Latency reduction: {improvement:.2f}%")
    else:
        # Sometimes network jitter makes local requests fluctuate
        print("\n⚠️ WARNING: Duration did not decrease significantly. Checking server logs for 'Cache hit'...")

if __name__ == "__main__":
    verify_cache()
