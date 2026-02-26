import requests
import time
import json

URL = "http://127.0.0.1:8000/finance-ai"

def verify_cache():
    payload = {
        "message": "Can I buy a coffee?",
        "expenses": "Budget: 5000, Spent: 0",
        "history": [],
        "app_data": "User: Test, Time: 2024-01-01 10:00"
    }

    print("--- Verifying Backend Cache ---")

    # First Request (Miss)
    start_time = time.time()
    try:
        response1 = requests.post(URL, json=payload)
        end_time = time.time()
        duration1 = end_time - start_time
        print(f"Request 1 (Potential Miss): {duration1:.4f}s")
        print(f"Response: {response1.text[:50]}...")
    except Exception as e:
        print(f"Error connecting to backend: {e}")
        return

    # Second Request (Hit)
    start_time = time.time()
    response2 = requests.post(URL, json=payload)
    end_time = time.time()
    duration2 = end_time - start_time
    print(f"Request 2 (Should be Hit): {duration2:.4f}s")
    print(f"Response: {response2.text[:50]}...")

    if duration2 < duration1 / 2:
        print("\n✅ SUCCESS: Cache hit is significantly faster!")
    else:
        print("\n⚠️ WARNING: Cache hit speedup not as expected, but it might be due to mock response speed.")

    if response1.text == response2.text:
        print("✅ SUCCESS: Responses match.")
    else:
        print("❌ FAILURE: Responses do not match.")

if __name__ == "__main__":
    verify_cache()
