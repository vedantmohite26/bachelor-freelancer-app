from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import InferenceClient
import os
import re
import hashlib
import json
import threading
from collections import OrderedDict
from dotenv import load_dotenv

load_dotenv()

class LRUCache:
    """Thread-safe LRU Cache for AI responses."""
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

# Initialize AI response cache
ai_cache = LRUCache()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

client = InferenceClient(model=MODEL_ID, token=HF_API_KEY)

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
    # BOLT OPTIMIZATION: AI Response Caching & Timestamp Normalization
    # Normalize high-entropy fields (timestamps) to maximize cache hits.
    # Regex trunctuates "System Date/Time: 2024-05-20 10:25:30" to hour precision.
    # BOLT OPTIMIZATION: Normalize high-entropy fields (timestamps) to maximize cache hits.
    # Regex trunctuates "System Date/Time: 2024-05-20 10:25:30" to hour precision.
    request.expenses = re.sub(
        r"(System Date/Time: \d{4}-\d{1,2}-\d{1,2} \d{1,2}):\d+",
        r"\1:00",
        request.expenses
    )

    # BOLT OPTIMIZATION: Use model_dump() for safe cache key serialization
    cache_key = hashlib.md5(
        json.dumps(request.model_dump(), sort_keys=True).encode()
    ).hexdigest()

    cached_response = ai_cache.get(cache_key)
    if cached_response:
        return cached_response

    print(f"Cache miss for request: {request.message}")

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
            return {"error": "HF_API_KEY is not configured on the server."}

        response = client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        ai_advice = response.choices[0].message.content
        ai_cache.put(cache_key, ai_advice)
        return ai_advice
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
