import requests
import json
import datetime
import io
import sys

# Force UTF-8 for stdout
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

URL = "https://bachelor-freelancer-app.onrender.com/finance-ai"

def test_prod():
    print(f"Testing Production URL: {URL}")
    
    # Scenario: Poor Student wanting Coffee
    # Expected: "Human-like" rejection (empathy + strictness)
    question = "Can I buy a ₹300 coffee?"
    app_data = "User Profile:\n- Name: ProdTester\n- Wallet Balance: ₹500\n\nWork Status:\n- Active Jobs: 0\n- Pending Applications: 0"
    
    now = datetime.datetime.now()
    full_data = f"System Date/Time: {now.strftime('%Y-%m-%d')}\nUser Data:\nBudget: 5000\nSpent: 0"
    
    payload = {
        "message": question,
        "expenses": full_data,
        "app_data": app_data,
        "history": []
    }
    
    try:
        response = requests.post(URL, json=payload, timeout=60)
        if response.status_code == 200:
            print("\n✅ Response Received:")
            print(f"AI: {response.text}")
        else:
            print(f"\n❌ Error: Status Code {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"\n❌ Exception: {e}")

if __name__ == "__main__":
    test_prod()
