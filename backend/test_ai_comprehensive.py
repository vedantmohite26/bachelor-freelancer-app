import requests
import sys

# Production URL for the AI backend
URL = "https://bachelor-freelancer-app.onrender.com/finance-ai"
# Local URL for testing
LOCAL_URL = "http://localhost:8000/finance-ai"

test_cases = [
    {
        "name": "Greeting",
        "message": "Hello, who are you?",
        "expenses": ""
    },
    {
        "name": "General Knowledge",
        "message": "What is the capital of France?",
        "expenses": ""
    },
    {
        "name": "Joke",
        "message": "Tell me a funny joke about money.",
        "expenses": ""
    },
    {
        "name": "Coding Question",
        "message": "How do I reverse a string in Python?",
        "expenses": ""
    },
    {
        "name": "Financial Advice (No Context)",
        "message": "How can I save money for a car?",
        "expenses": ""
    },
    {
        "name": "Financial Advice (With Context)",
        "message": "Can I afford to buy a new phone for $800?",
        "expenses": "Monthly Income: $3000, Rent: $1000, Food: $500, Savings: $200"
    },
    {
        "name": "Budget Analysis",
        "message": "Analyze my spending and give me 3 tips.",
        "expenses": "Transactions:\n2023-10-01: -50 (Coffee)\n2023-10-02: -150 (Dining out)\n2023-10-03: -200 (Subscription)\n2023-10-04: +2000 (Salary)"
    },
    {
        "name": "Life Advice",
        "message": "I'm feeling a bit stressed about work, any advice?",
        "expenses": ""
    },
    {
        "name": "Identity",
        "message": "Who are you and what is your purpose?",
        "expenses": ""
    },
    {
        "name": "Conflicting Info",
        "message": "I earn $5000 but I'm broke. Why?",
        "expenses": "Income: $5000, Rent: $1000, Food: $500, Misc: $3500"
    },
    {
        "name": "Large Numbers",
        "message": "Can I buy a private jet for $10,000,000?",
        "expenses": "Monthly Income: $2000, Savings: $50"
    },
    {
        "name": "Non-English (Hindi)",
        "message": "मुझे पैसे बचाने के लिए कुछ सुझाव दें।",
        "expenses": "Income: 50000, Expenses: 40000"
    }
]

def run_tests(target_url):
    print(f"Target URL: {target_url}")
    print("="*50)
    for case in test_cases:
        print(f"--- Testing: {case['name']} ---")
        print(f"User: {case['message']}")
        try:
            response = requests.post(target_url, json={
                "message": case['message'],
                "expenses": case['expenses']
            }, timeout=30)
            if response.status_code == 200:
                print(f"AI: {response.json()}")
            else:
                print(f"Error: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"Exception: {e}")
        print("-" * 30)

if __name__ == "__main__":
    target = URL
    if len(sys.argv) > 1 and sys.argv[1] == "local":
        target = LOCAL_URL
    run_tests(target)
