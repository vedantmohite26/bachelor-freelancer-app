from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import InferenceClient
import os
import re
import hashlib
import json
from collections import OrderedDict
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# LRU Cache implementation
class LRUCache:
    def __init__(self, capacity: int = 100):
        self.cache = OrderedDict()
        self.capacity = capacity

    def get(self, key: str):
        if key not in self.cache:
            return None
        self.cache.move_to_end(key)
        return self.cache[key]

    def put(self, key: str, value: str):
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = value
        if len(self.cache) > self.capacity:
            self.cache.popitem(last=False)

response_cache = LRUCache(capacity=100)

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
    # --- Performance Optimization: Input Normalization ---
    # Truncate minutes from System Date/Time to increase cache hits for frequent requests
    # Example: "System Date/Time: 2024-05-15 10:15" -> "System Date/Time: 2024-05-15 10:00"
    normalized_expenses = re.sub(r"(System Date/Time: \d{4}-\d{2}-\d{2} \d{2}):\d{2}", r"\1:00", request.expenses)

    # --- Performance Optimization: LRU Caching ---
    # Generate cache key from normalized request data
    cache_data = {
        "message": request.message,
        "expenses": normalized_expenses,
        "history": request.history,
        "app_data": request.app_data
    }
    cache_key = hashlib.md5(json.dumps(cache_data, sort_keys=True).encode()).hexdigest()

    cached_response = response_cache.get(cache_key)
    if cached_response:
        print(f"Cache Hit for: {request.message}")
        return cached_response

    print(f"Cache Miss for: {request.message}")
    
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
        # If no API key, return a mock response for development/testing
        if not HF_API_KEY:
            mock_response = "I'm a strict bot! No spending today! (Mock)"
            response_cache.put(cache_key, mock_response)
            return mock_response

        response = client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        ai_advice = response.choices[0].message.content

        # Save to cache
        response_cache.put(cache_key, ai_advice)
        return ai_advice
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
