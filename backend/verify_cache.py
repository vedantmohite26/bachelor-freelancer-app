import requests
import time
import hashlib
import json

URL = "http://127.0.0.1:8000/finance-ai"

def test_cache():
    payload = {
        "message": "Can I buy a ₹300 coffee?",
        "expenses": "System Date/Time: 2024-01-01 12:00\nUser Data:\nBudget: 5000\nSpent: 0",
        "app_data": "User Profile: Test",
        "history": []
    }

    print("Sending first request (should be a cache miss)...")
    start_time = time.time()
    response1 = requests.post(URL, json=payload)
    duration1 = time.time() - start_time
    print(f"Request 1 took: {duration1:.4f}s")
    print(f"Response 1: {response1.text}")

    print("\nSending second identical request (should be a cache hit)...")
    start_time = time.time()
    response2 = requests.post(URL, json=payload)
    duration2 = time.time() - start_time
    print(f"Request 2 took: {duration2:.4f}s")
    print(f"Response 2: {response2.text}")

    if response1.text == response2.text:
        print("\n✅ Success: Responses are identical.")
    else:
        print("\n❌ Error: Responses are different.")

    if duration2 < duration1:
        print(f"✅ Success: Second request was faster ({duration1/duration2:.1f}x speedup).")
    else:
        print("\n⚠️ Warning: Second request was not significantly faster. Cache might not be effective or overhead is high.")

    # Test with slightly different payload (should be a cache miss)
    print("\nSending modified request (should be a cache miss)...")
    payload["message"] = "Can I buy a ₹301 coffee?"
    start_time = time.time()
    response3 = requests.post(URL, json=payload)
    duration3 = time.time() - start_time
    print(f"Request 3 took: {duration3:.4f}s")

if __name__ == "__main__":
    try:
        test_cache()
    except Exception as e:
        print(f"Error connecting to server: {e}")
        print("Make sure the backend is running on port 8000.")
