from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import InferenceClient
import os
import hashlib
import json
import re
from collections import OrderedDict
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

client = InferenceClient(model=MODEL_ID, token=HF_API_KEY)

class LRUCache:
    """
    A simple In-Memory LRU Cache to store AI responses.
    Reduces latency and API costs for identical or similar requests.
    """
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

# Initialize global cache
response_cache = LRUCache(capacity=100)

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
    print(f"Received request: {request.message}")
    print(f"App Data: {request.app_data}")  # Debug print

    # 1. Normalize high-entropy fields (like timestamp) to increase cache hit rate.
    # We truncate the "System Date/Time" to the hour (YYYY-MM-DD HH:00)
    normalized_expenses = re.sub(
        r"(System Date/Time: \d{4}-\d{2}-\d{2} \d{2}):\d{2}",
        r"\1:00",
        request.expenses
    )

    # 2. Generate cache key based on normalized request content
    cache_payload = {
        "message": request.message,
        "expenses": normalized_expenses,
        "history": request.history,
        "app_data": request.app_data
    }
    cache_key = hashlib.md5(json.dumps(cache_payload, sort_keys=True).encode()).hexdigest()

    # 3. Check cache
    cached_response = response_cache.get(cache_key)
    if cached_response:
        print("Returning cached response.")
        return cached_response
    
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
        # If no HF_API_KEY, we return a mock response to allow testing the caching layer
        if not HF_API_KEY:
            mock_response = f"I'm your big sibling. Regarding your '{request.message}', you know you should save! (Mock Response)"
            response_cache.put(cache_key, mock_response)
            return mock_response

        response = client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        ai_content = response.choices[0].message.content

        # 4. Store in cache
        response_cache.put(cache_key, ai_content)
        return ai_content
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
