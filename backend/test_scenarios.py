import requests
import json
import datetime
import sys
import io

# Force UTF-8 for stdout
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# URL = "http://127.0.0.1:8000/finance-ai" # Local (if running)
# URL = "http://127.0.0.1:8001/finance-ai" # Local Custom Port
URL = "https://bachelor-freelancer-app.onrender.com/finance-ai" # Production

def test_question(category, question, budget_info=None, app_data=None):
    print(f"\n--- Testing {category} ---")
    print(f"Q: {question}")
    
    now = datetime.datetime.now()
    date_string = now.strftime("%Y-%m-%d %H:%M")
    
    if budget_info is None:
        budget_info = "Budget: 5000\nSpent: 20"
    
    full_data = f"System Date/Time: {date_string}\nUser Data:\n{budget_info}\nRecent Transactions:\nNone"
    
    encoded_app_data = ""
    if app_data:
        encoded_app_data = app_data

    payload = {
        "message": question,
        "expenses": full_data,
        "app_data": encoded_app_data
    }
    
    try:
        response = requests.post(URL, json=payload, timeout=60)
        if response.status_code == 200:
            print(f"A: {response.text}")
        else:
            print(f"Error: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    # 1. General Knowledge
    # test_question("General Knowledge", "Tell me a short joke about programming.")
    
    # 2. App Data Context with Logic Test
    test_app_data = "User Profile:\n- Name: Alice\n- Wallet Balance: ₹5000\n\nWork Status:\n- Active Jobs: 0\n- Pending Applications: 0"
    
    # Test 1: Necessary Expense (Exam Pen)
    test_question("Logic Test: NEED", "can I buy 10rs pen for exam?", app_data=test_app_data)
    
    # Test 2: Unnecessary Expense (Coffee)
    test_question("Logic Test: WANT", "can I buy a ₹300 coffee?", app_data=test_app_data)
