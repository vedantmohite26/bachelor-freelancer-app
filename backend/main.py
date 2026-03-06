from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import AsyncInferenceClient
import os
import hashlib
import json
from collections import OrderedDict
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

# Use AsyncInferenceClient for better concurrency
client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

# Bolt Optimization: Simple In-Memory LRU Cache
CACHE_CAPACITY = 100
ai_cache = OrderedDict()

class FinanceRequest(BaseModel):
    message: str
    expenses: str
    history: list[dict] = []
    app_data: str = ""  # New field for general app data

def get_cache_key(request: FinanceRequest) -> str:
    """Generate a unique MD5 hash for the request payload to use as a cache key."""
    payload = f"{request.message}|{request.expenses}|{json.dumps(request.history)}|{request.app_data}"
    return hashlib.md5(payload.encode()).hexdigest()

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
async def finance_ai(request: FinanceRequest):
    # Bolt Optimization: Check cache first
    cache_key = get_cache_key(request)
    if cache_key in ai_cache:
        # Move to end to maintain LRU order
        ai_cache.move_to_end(cache_key)
        return ai_cache[cache_key]

    # Mock Logic for development when API Key is missing
    # This also allows verifying the caching layer without an active API key
    if not HF_API_KEY:
        mock_response = "I'm your AI sibling! (Mock: API Key missing). Save your money, don't buy that coffee! ☕"
        ai_cache[cache_key] = mock_response
        if len(ai_cache) > CACHE_CAPACITY:
            ai_cache.popitem(last=False)
        return mock_response

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
        # Bolt Optimization: Use await with the async client
        response = await client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        ai_response = response.choices[0].message.content

        # Bolt Optimization: Update cache with the new response
        ai_cache[cache_key] = ai_response
        if len(ai_cache) > CACHE_CAPACITY:
            ai_cache.popitem(last=False)

        return ai_response
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    # Bolt: Standardize on port 8000 for local development
    uvicorn.run(app, host="0.0.0.0", port=8000)
