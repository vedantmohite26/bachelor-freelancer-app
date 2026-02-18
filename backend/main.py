from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import AsyncInferenceClient
import os
from dotenv import load_dotenv
from collections import OrderedDict

load_dotenv()

app = FastAPI()

# --- LRU Cache for AI Responses ---
# This significantly improves performance for repeated or identical queries
class LRUCache:
    def __init__(self, capacity: int):
        self.cache = OrderedDict()
        self.capacity = capacity

    def get(self, key):
        if key not in self.cache:
            return None
        self.cache.move_to_end(key)
        return self.cache[key]

    def put(self, key, value):
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = value
        if len(self.cache) > self.capacity:
            self.cache.popitem(last=False)

# Initialize cache with capacity of 100 entries to prevent memory leaks
ai_response_cache = LRUCache(capacity=100)

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

# Use AsyncInferenceClient for non-blocking I/O
client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

class FinanceRequest(BaseModel):
    message: str
    expenses: str
    history: list[dict] = []
    app_data: str = ""  # Field for general app data

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
async def finance_ai(request: FinanceRequest):
    """
    Optimized endpoint with caching and async processing.
    """
    print(f"Received request: {request.message}")
    
    # 1. Cache Check
    # Create a hashable cache key from the request data
    history_tuple = tuple((m.get('role', ''), m.get('content', '')) for m in request.history)
    cache_key = (request.message, request.expenses, history_tuple, request.app_data)

    cached_response = ai_response_cache.get(cache_key)
    if cached_response:
        print("Returning cached AI response ⚡")
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
        # Use await for non-blocking call to Hugging Face
        response = await client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        content = response.choices[0].message.content

        # Store in cache before returning
        ai_response_cache.put(cache_key, content)
        return content
    except Exception as e:
        # Fallback to a helpful error message if the LLM fails
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    # Increased workers or just using async handles more concurrent requests
    uvicorn.run(app, host="0.0.0.0", port=8000)
