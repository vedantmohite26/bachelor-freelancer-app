import requests
import time
import json

URL = "http://127.0.0.1:8000/finance-ai"

def benchmark():
    payload = {
        "message": "Can I buy a coffee?",
        "expenses": "System Date/Time: 2023-10-27 10:15\nUser Data:\nBudget: 5000\nSpent: 0",
        "history": [],
        "app_data": "User Profile:\n- Name: TestUser\n- Wallet Balance: ₹500"
    }

    print("Running benchmark...")

    # First request (cold)
    start = time.time()
    try:
        response = requests.post(URL, json=payload)
        end = time.time()
        print(f"Cold request took: {end - start:.4f}s")
    except Exception as e:
        print(f"Error: {e}")
        return

    # Second request (identical)
    start = time.time()
    response = requests.post(URL, json=payload)
    end = time.time()
    print(f"Identical request took: {end - start:.4f}s")

    # Third request (normalized timestamp - if implemented)
    payload_normalized = payload.copy()
    payload_normalized["expenses"] = "System Date/Time: 2023-10-27 10:45\nUser Data:\nBudget: 5000\nSpent: 0"
    start = time.time()
    response = requests.post(URL, json=payload_normalized)
    end = time.time()
    print(f"Normalized request (different minute) took: {end - start:.4f}s")

if __name__ == "__main__":
    benchmark()
