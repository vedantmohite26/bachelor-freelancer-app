import requests
import time
import json
import hashlib

URL = "http://127.0.0.1:8000/finance-ai"

def get_performance():
    payload = {
        "message": "Can I buy a coffee for ₹200?",
        "expenses": "Budget: 5000, Spent: 100",
        "app_data": "User: Test",
        "history": []
    }

    print("--- Performance Verification ---")

    # 1. First Request (Cold)
    start_time = time.time()
    response1 = requests.post(URL, json=payload)
    cold_time = time.time() - start_time
    print(f"Cold Request Time: {cold_time:.4f}s")
    print(f"Response: {response1.text[:50]}...")

    # 2. Second Request (Warm - should be cached)
    start_time = time.time()
    response2 = requests.post(URL, json=payload)
    warm_time = time.time() - start_time
    print(f"Warm Request Time: {warm_time:.4f}s")
    print(f"Response: {response2.text[:50]}...")

    if response1.text == response2.text:
        print("✅ Responses match.")
    else:
        print("❌ Responses do not match!")

    if warm_time < cold_time:
        improvement = (cold_time - warm_time) / cold_time * 100
        print(f"⚡ Performance Improvement: {improvement:.2f}% faster")
    else:
        print("⚠️ No performance improvement detected.")

    # 3. Different Request (Should not be cached)
    payload["message"] = "Can I buy a pen for ₹10?"
    start_time = time.time()
    response3 = requests.post(URL, json=payload)
    diff_time = time.time() - start_time
    print(f"Different Request Time: {diff_time:.4f}s")

if __name__ == "__main__":
    try:
        get_performance()
    except Exception as e:
        print(f"Error: {e}")
        print("Make sure the backend is running on port 8000.")
