from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import InferenceClient
import os
import time
import re
import hashlib
import json
import collections
import threading
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

client = InferenceClient(model=MODEL_ID, token=HF_API_KEY)

# LRU Cache implementation for performance optimization
class LRUCache:
    def __init__(self, capacity: int):
        self.cache = collections.OrderedDict()
        self.capacity = capacity
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

ai_cache = LRUCache(capacity=100)

class FinanceRequest(BaseModel):
    message: str
    expenses: str
    history: list[dict] = []
    app_data: str = ""  # New field for general app data

def get_cache_key(request: FinanceRequest) -> str:
    # Normalize timestamp in expenses to hour-precision (YYYY-MM-DD HH:00) to maximize cache hits
    # The frontend format is: "System Date/Time: 2024-03-20 14:35"
    normalized_expenses = re.sub(
        r"(System Date/Time: \d{4}-\d{1,2}-\d{1,2} \d{1,2}):\d+",
        r"\1:00",
        request.expenses
    )

    # Hash the components to create a fixed-length key for efficient lookup
    key_data = {
        "msg": request.message,
        "exp": normalized_expenses,
        "hist": request.history,
        "app": request.app_data
    }
    return hashlib.md5(json.dumps(key_data, sort_keys=True).encode()).hexdigest()

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
def finance_ai(request: FinanceRequest):
    # Performance check: Try to return cached response
    cache_key = get_cache_key(request)
    cached_response = ai_cache.get(cache_key)
    if cached_response:
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
        # Mocking AI response if HF_API_KEY is missing for local development/testing
        if not HF_API_KEY:
            # Performance boost measurement: adding artificial delay for cold start mock (10ms)
            time.sleep(0.01)
            mock_ans = "Listen, money doesn't grow on trees. Think carefully before spending ₹ on this!"
            ai_cache.put(cache_key, mock_ans)
            return mock_ans

        response = client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        result = response.choices[0].message.content

        # Store in cache for future identical requests
        ai_cache.put(cache_key, result)
        return result
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
