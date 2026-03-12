from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import AsyncInferenceClient
import os
from dotenv import load_dotenv
import collections
import hashlib
import json
import re

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

# Use AsyncInferenceClient for better concurrency
client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

# Simple LRU Cache for AI responses
# Capacity: 100 entries
ai_response_cache = collections.OrderedDict()
CACHE_CAPACITY = 100

def get_cache_key(request: 'FinanceRequest') -> str:
    """
    Generates a cache key based on the request payload.
    Normalizes the 'System Date/Time' to hour precision to increase cache hits.
    """
    # Normalize timestamp to hour precision (e.g., 2024-05-10 09:05 -> 2024-05-10 09:00)
    # This allows multiple requests within the same hour to hit the cache even if the exact minute differs.
    normalized_expenses = re.sub(
        r"(System Date/Time: \d{4}-\d{2}-\d{2} \d{2}):\d{2}",
        r"\1:00",
        request.expenses
    )

    payload_str = json.dumps({
        "message": request.message,
        "expenses": normalized_expenses,
        "history": request.history,
        "app_data": request.app_data
    }, sort_keys=True)

    return hashlib.md5(payload_str.encode()).hexdigest()

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
    # Performance Optimization: Caching
    cache_key = get_cache_key(request)
    if cache_key in ai_response_cache:
        # Move to end (LRU behavior)
        ai_response_cache.move_to_end(cache_key)
        print(f"Cache HIT for request: {request.message[:50]}...")
        return ai_response_cache[cache_key]

    print(f"Received request: {request.message}")
    
    # Mock response if API key is missing (for local dev/testing)
    if not HF_API_KEY:
        mock_response = "I'm your financial assistant. I'm currently in offline mode because no API key was found, but I can still tell you that saving is a great habit! 💰"
        # Even mock responses should be cached to verify the caching layer
        ai_response_cache[cache_key] = mock_response
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
        response = await client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        advice = response.choices[0].message.content

        # Store in cache
        ai_response_cache[cache_key] = advice
        if len(ai_response_cache) > CACHE_CAPACITY:
            ai_response_cache.popitem(last=False)

        return advice
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
