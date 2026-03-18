from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import InferenceClient
import os
from dotenv import load_dotenv
import hashlib
import json
import re
from collections import OrderedDict
import threading

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

# Use mock if no API key is present
if HF_API_KEY:
    client = InferenceClient(model=MODEL_ID, token=HF_API_KEY)
else:
    client = None

class FinanceRequest(BaseModel):
    message: str
    expenses: str
    history: list[dict] = []
    app_data: str = ""

class LRUCache:
    """
    In-memory Least Recently Used (LRU) cache to store AI responses.
    Reduces latency and cost by reusing responses for identical or normalized requests.
    """
    def __init__(self, capacity: int = 100):
        self.cache = OrderedDict()
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

# Global cache instance
ai_cache = LRUCache(capacity=100)

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
def finance_ai(request: FinanceRequest):
    # Performance Optimization: Normalize expenses to hour precision to increase cache hit rate.
    # High-entropy fields like minutes/seconds in timestamps are truncated.
    # Pattern: "System Date/Time: YYYY-MM-DD HH:MM" -> "System Date/Time: YYYY-MM-DD HH:00"
    normalized_expenses = re.sub(
        r"(System Date/Time: \d{4}-\d{1,2}-\d{1,2} \d{1,2}):\d{1,2}",
        r"\1:00",
        request.expenses
    )
    
    # Generate stable cache key by hashing the request components
    key_data = {
        "message": request.message.strip().lower(),
        "expenses": normalized_expenses,
        "history": request.history,
        "app_data": request.app_data
    }
    # Sort keys to ensure consistent JSON representation for hashing
    stable_json = json.dumps(key_data, sort_keys=True).encode()
    cache_key = hashlib.md5(stable_json).hexdigest()

    cached_response = ai_cache.get(cache_key)
    if cached_response:
        # Cache Hit: Returns in ~1-5ms vs ~2000-5000ms for AI inference
        return cached_response

    if not client:
        # Mock response if no API key is provided (useful for development/testing)
        mock_response = f"I'm Bolt's mock assistant. You asked: {request.message}. (No HF_API_KEY found)"
        ai_cache.put(cache_key, mock_response)
        return mock_response

    # Prepare context for AI model
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
        # Actual AI model inference
        response = client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        content = response.choices[0].message.content
        # Store result in cache for future identical/similar requests
        ai_cache.put(cache_key, content)
        return content
    except Exception as e:
        return {"error": f"Error during AI inference: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
