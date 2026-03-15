import requests
import time
import json

# URL = "https://bachelor-freelancer-app.onrender.com/finance-ai"
URL = "http://127.0.0.1:8000/finance-ai"

def benchmark():
    payload1 = {
        "message": "Can I buy a ₹300 coffee?",
        "expenses": "System Date/Time: 2024-05-20 14:35\nUser Data:\nBudget: 5000\nSpent: 0",
        "app_data": "User Profile:\n- Name: TestUser\n- Wallet Balance: ₹500",
        "history": []
    }

    payload2 = {
        "message": "Can I buy a ₹300 coffee?",
        "expenses": "System Date/Time: 2024-05-20 14:59\nUser Data:\nBudget: 5000\nSpent: 0",
        "app_data": "User Profile:\n- Name: TestUser\n- Wallet Balance: ₹500",
        "history": []
    }

    print("--- Starting Benchmark ---")

    # Request 1
    start = time.time()
    try:
        response = requests.post(URL, json=payload1, timeout=60)
        end = time.time()
        print(f"Request 1 (14:35) Time: {end - start:.4f}s")
    except Exception as e:
        print(f"Request 1 Failed: {e}")

    # Request 2 (Identical payload)
    start = time.time()
    try:
        response = requests.post(URL, json=payload1, timeout=60)
        end = time.time()
        print(f"Request 2 (Identical 14:35) Time: {end - start:.4f}s")
    except Exception as e:
        print(f"Request 2 Failed: {e}")

    # Request 3 (Different minutes, same hour)
    start = time.time()
    try:
        response = requests.post(URL, json=payload2, timeout=60)
        end = time.time()
        print(f"Request 3 (14:59 - same hour) Time: {end - start:.4f}s")
    except Exception as e:
        print(f"Request 3 Failed: {e}")

    print("\nNote: For real AI requests, Request 1 would take 2-5 seconds.")
    print("--- Benchmark Finished ---")

if __name__ == "__main__":
    benchmark()
