import time
import requests

def benchmark():
    url = "http://localhost:8000/finance-ai"
    payload = {
        "message": "Can I buy a ₹300 coffee?",
        "expenses": "Budget: 5000, Spent: 4000",
        "app_data": "User Profile: Student",
        "history": []
    }

    print("--- First Request (Expected to be slow) ---")
    start = time.time()
    response = requests.post(url, json=payload)
    end = time.time()
    print(f"Status: {response.status_code}")
    print(f"Time: {end - start:.4f}s")
    print(f"Response: {response.text[:50]}...")

    print("\n--- Second Request (Identical, expected to be fast if cached) ---")
    start = time.time()
    response = requests.post(url, json=payload)
    end = time.time()
    print(f"Status: {response.status_code}")
    print(f"Time: {end - start:.4f}s")
    print(f"Response: {response.text[:50]}...")

if __name__ == "__main__":
    benchmark()
