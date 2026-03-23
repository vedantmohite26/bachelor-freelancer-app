from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import InferenceClient
import os
import collections
import threading
import hashlib
import json
import re
import time
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

client = InferenceClient(model=MODEL_ID, token=HF_API_KEY)

class LRUCache:
    """Thread-safe LRU Cache for AI responses."""
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = collections.OrderedDict()
        self.lock = threading.Lock()

    def get(self, key: str):
        with self.lock:
            if key not in self.cache:
                return None
            self.cache.move_to_end(key)
            return self.cache[key]

    def put(self, key: str, value: str):
        with self.lock:
            if key in self.cache:
                self.cache.move_to_end(key)
            self.cache[key] = value
            if len(self.cache) > self.capacity:
                self.cache.popitem(last=False)

# Initialize cache with capacity 100
ai_cache = LRUCache(100)

class FinanceRequest(BaseModel):
    message: str
    expenses: str
    history: list[dict] = []
    app_data: str = ""  # New field for general app data

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
def finance_ai(request: FinanceRequest):
    # Normalize timestamp to the hour for better cache efficiency
    # Example: "System Date/Time: 2024-05-20 14:30" -> "System Date/Time: 2024-05-20 14"
    normalized_expenses = re.sub(
        r"(System Date/Time: \d{4}-\d{1,2}-\d{1,2} \d{1,2}):\d+",
        r"\1",
        request.expenses
    )

    # Generate cache key from request data
    cache_input = {
        "message": request.message,
        "expenses": normalized_expenses,
        "history": request.history,
        "app_data": request.app_data
    }
    cache_key = hashlib.md5(json.dumps(cache_input, sort_keys=True).encode()).hexdigest()

    # Check cache for performance boost
    cached_response = ai_cache.get(cache_key)
    if cached_response:
        print(f"Cache hit for: {request.message[:20]}...")
        return cached_response

    print(f"Received request: {request.message}")
    print(f"App Data: {request.app_data}")  # Debug print
    
    # Format history for context
    history_context = ""
    if request.history:
        history_context = "\n\nChat History:\n" + "\n".join([f"{msg['role']}: {msg['content']}" for msg in request.history[-5:]])

    messages = [
        {
            "role": "system",
            "content": "You are a **strict but caring big brother/sister**. You want your sibling (the user) to save money and succeed, so you must **STOP unnecessary spending**.\n\n### How to Think Humanly:\n1. **Empathize**: Acknowledge their want (e.g., \"I know coffee matches the rain...\").\n2. **Be Firm**: ...but reject it if they are broke (e.g., \"...but you have ₹500. No.\").\n3. **Logic**: Needs (Food, Exam) = YES. Wants (Games, Cafe) = NO if broke.\n\n### Rules for Answer:\n1. **Short**: Max 2 sentences.\n2. **Natural**: specific, no robotic lists. Use emoji occasionally.\n3. **Indian Context**: Use ₹.\n\n**Goal**: Be the strict voice of reason they love/hate."
        },
        {
            "role": "user",
            "content": f"App Data:\n{request.app_data}\n\nFinancial Context (if relevant):\n{request.expenses}{history_context}\n\nUser Question:\n{request.message}"
        }
    ]

    try:
        if not HF_API_KEY:
            raise ValueError("Missing HF_API_KEY")

        response = client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        ans = response.choices[0].message.content
        ai_cache.put(cache_key, ans)
        return ans
    except Exception as e:
        # Fallback for missing API key or error during local development/benchmark
        if not HF_API_KEY or "401" in str(e):
            time.sleep(0.5)  # Simulate AI inference delay
            mock_ans = "No. Reason: You should save that money. (Mock Response)"
            ai_cache.put(cache_key, mock_ans)
            return mock_ans
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
