import requests
import json
import time

URL = "http://127.0.0.1:8000/finance-ai"

def verify_cache():
    payload = {
        "message": "Can I buy a ₹300 coffee?",
        "expenses": "System Date/Time: 2024-05-20 10:00\nUser Data:\nBudget: 5000\nSpent: 0",
        "app_data": "User Profile:\n- Name: TestUser\n- Wallet Balance: ₹500",
        "history": []
    }

    print("--- Request 1 (Should call AI or Mock) ---")
    start_time = time.time()
    response1 = requests.post(URL, json=payload)
    end_time = time.time()
    print(f"Response 1: {response1.text}")
    print(f"Time taken: {end_time - start_time:.4f}s")

    print("\n--- Request 2 (Should be from Cache) ---")
    start_time = time.time()
    response2 = requests.post(URL, json=payload)
    end_time = time.time()
    print(f"Response 2: {response2.text}")
    print(f"Time taken: {end_time - start_time:.4f}s")

    if response1.text == response2.text:
        print("\n✅ SUCCESS: Responses are identical.")
        if (end_time - start_time) < 0.1: # Cache should be very fast
             print("✅ SUCCESS: Second request was significantly faster (served from cache).")
        else:
             print("⚠️ WARNING: Second request was not significantly faster, but identical.")
    else:
        print("\n❌ FAILURE: Responses are different.")

if __name__ == "__main__":
    verify_cache()
