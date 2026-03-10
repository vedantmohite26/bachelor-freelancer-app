import requests
import time
import datetime

URL = "http://127.0.0.1:8000/finance-ai"

payload = {
    "message": "Can I buy a ₹300 coffee?",
    "expenses": "System Date/Time: 2024-01-01 10:00\nUser Data:\nBudget: 5000\nSpent: 0",
    "app_data": "User Profile:\n- Name: TestUser\n- Wallet Balance: ₹500",
    "history": []
}

print("Starting performance test...")

# First request (should be uncached)
start = time.time()
requests.post(URL, json=payload)
end = time.time()
print(f"First request took: {end - start:.4f}s")

# Second request (should be cached)
start = time.time()
requests.post(URL, json=payload)
end = time.time()
print(f"Second request (cached) took: {end - start:.4f}s")
