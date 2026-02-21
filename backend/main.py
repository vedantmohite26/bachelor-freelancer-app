from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import AsyncInferenceClient
import os
from dotenv import load_dotenv
from collections import OrderedDict
import hashlib
import json

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

# Use AsyncInferenceClient for better concurrent request handling
client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

# Simple LRU Cache to store and reuse AI responses for identical requests
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

ai_cache = LRUCache(capacity=100)

class FinanceRequest(BaseModel):
    message: str
    expenses: str
    history: list[dict] = []
    app_data: str = ""  # New field for general app data

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
async def finance_ai(request: FinanceRequest):
    print(f"Received request: {request.message}")

    # Create a unique cache key based on the request content
    # We include all relevant fields to ensure context-aware caching
    cache_input = {
        "message": request.message,
        "expenses": request.expenses,
        "history": request.history[-5:] if request.history else [],
        "app_data": request.app_data
    }
    cache_key = hashlib.md5(json.dumps(cache_input, sort_keys=True).encode()).hexdigest()

    # Check if we have a cached response
    cached_response = ai_cache.get(cache_key)
    if cached_response:
        print(f"Cache hit for request: {request.message}")
        return cached_response

    print(f"Cache miss. Calling AI for: {request.message}")
    
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
        # If no API key, return mock response for local development
        if not HF_API_KEY:
            mock_response = "I'm your big sibling! I'd love to help, but the HF_API_KEY is missing. Let's just say you should save that ₹!"
            ai_cache.put(cache_key, mock_response)
            return mock_response

        response = await client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        content = response.choices[0].message.content

        # Store in cache before returning
        ai_cache.put(cache_key, content)
        return content
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
