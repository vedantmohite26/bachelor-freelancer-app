from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import AsyncInferenceClient
import os
import re
import json
import hashlib
from collections import OrderedDict
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# In-memory LRU Cache for AI responses
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

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

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
    # Payload Normalization for better caching:
    # Truncate minutes/seconds from System Date/Time to increase cache hit rate for repeated same-hour queries.
    # Pattern looks for "System Date/Time: YYYY-MM-DD HH:MM"
    normalized_expenses = re.sub(r"(System Date/Time: \d{4}-\d{2}-\d{2} \d{2}):\d{2}", r"\1:00", request.expenses)

    # Generate unique cache key based on request content
    cache_payload = {
        "message": request.message,
        "expenses": normalized_expenses,
        "history": request.history,
        "app_data": request.app_data
    }
    cache_key = hashlib.md5(json.dumps(cache_payload, sort_keys=True).encode()).hexdigest()

    cached_response = ai_cache.get(cache_key)
    if cached_response:
        return cached_response

    print(f"Received request: {request.message}")
    
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

    # Use mock response if API Key is missing (facilitates testing/development)
    if not HF_API_KEY:
        mock_response = "I'm currently in offline mode (missing API key), but as your big brother, I say: save your money! 💸"
        ai_cache.put(cache_key, mock_response)
        return mock_response

    try:
        response = await client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        result = response.choices[0].message.content
        ai_cache.put(cache_key, result)
        return result
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
