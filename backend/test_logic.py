import requests
import json
import datetime
import io
import sys

# Force UTF-8 for stdout
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# URL = "https://bachelor-freelancer-app.onrender.com/finance-ai"
URL = "http://127.0.0.1:8000/finance-ai"

def log(msg):
    print(msg)
    with open("test_log.txt", "a", encoding="utf-8") as f:
        f.write(msg + "\n")

def test(user_type, wallet, active_jobs, question, expected_decision, history=None):
    log(f"\n--- Scenario: {user_type} (₹{wallet}) ---")
    log(f"Q: {question}")
    
    app_data = f"User Profile:\n- Name: TestUser\n- Wallet Balance: ₹{wallet}\n\nWork Status:\n- Active Jobs: {active_jobs}\n- Pending Applications: 0"
    
    now = datetime.datetime.now()
    full_data = f"System Date/Time: {now.strftime('%Y-%m-%d')}\nUser Data:\nBudget: 5000\nSpent: 0"
    
    payload = {
        "message": question,
        "expenses": full_data,
        "app_data": app_data,
        "history": history if history else []
    }
    
    try:
        response = requests.post(URL, json=payload, timeout=60)
        ans = response.text
        log(f"AI: {ans}")
        
        # Simple heuristic check
        if expected_decision == "YES" and ("yes" in ans.lower() or "buy" in ans.lower()):
            log("✅ PASS")
        elif expected_decision == "NO" and ("no" in ans.lower() or "don't" in ans.lower()):
            log("✅ PASS")
        else:
            log(f"⚠️  MANUAL CHECK NEEDED (Expected {expected_decision})")
        return ans
            
    except Exception as e:
        log(f"Error: {e}")
        return ""

if __name__ == "__main__":
    open("test_log.txt", "w").close() # Clear log file
    
    # 1. Poor Student - NEED (Exam Pen) -> YES
    test("Poor Student", 500, 0, "Can I buy a ₹10 pen for exam?", "YES")
    
    # 2. Poor Student - WANT (Coffee) -> NO
    test("Poor Student", 500, 0, "Can I buy a ₹300 coffee?", "NO")
    
    # 3. Rich Freelancer - WANT (Coffee) -> NO (Strictness check)
    test("Rich Freelancer", 50000, 5, "Can I buy a ₹300 coffee?", "NO")
    
    # 4. Broke - NEED (Food) -> YES
    test("Broke", 50, 0, "Can I buy ₹40 food?", "YES")
    
    # 5. Broke - WANT (Cinema) -> NO
    test("Broke", 50, 0, "Can I go to cinema (₹200)?", "NO")

    # 6. Learning Test (Simulated)
    log("\n--- Testing Learning Capability ---")
    q = "Can I buy a ₹200 comic book?"
    log(f"Initial Q: {q}")
    history = [
        {"role": "user", "content": q},
        {"role": "assistant", "content": "Yes, buy the book."},
        {"role": "user", "content": "No! Comics are unnecessary expenses. Use strict logic!"}
    ]
    test("Learning User", 1000, 0, "Can I buy a ₹200 comic book?", "NO", history=history)
