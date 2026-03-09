from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import AsyncInferenceClient
import os
from dotenv import load_dotenv
import hashlib
import json
from collections import OrderedDict

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

# Use AsyncInferenceClient for better concurrency
client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

# Simple LRU Cache for performance optimization (Capacity 100)
# This reduces latency and costs for identical requests
MAX_CACHE_SIZE = 100
response_cache = OrderedDict()

class FinanceRequest(BaseModel):
    message: str
    expenses: str
    history: list[dict] = []
    app_data: str = ""  # New field for general app data

def get_cache_key(request: FinanceRequest) -> str:
    """Generate a unique MD5 hash key for the request payload."""
    payload_str = json.dumps({
        "message": request.message,
        "expenses": request.expenses,
        "history": request.history,
        "app_data": request.app_data
    }, sort_keys=True)
    return hashlib.md5(payload_str.encode()).hexdigest()

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
async def finance_ai(request: FinanceRequest):
    print(f"Received request: {request.message}")
    
    # 1. Check Cache first
    cache_key = get_cache_key(request)
    if cache_key in response_cache:
        # Move to end (most recently used)
        response_cache.move_to_end(cache_key)
        print("Returning cached response.")
        return response_cache[cache_key]

    # 2. Handle missing API key with a mock response (cached)
    if not HF_API_KEY:
        mock_response = "I'm currently in development mode. Please set your HF_API_KEY to get real financial advice. For now: Keep saving! 💰"
        response_cache[cache_key] = mock_response
        if len(response_cache) > MAX_CACHE_SIZE:
            response_cache.popitem(last=False)
        return mock_response

    # 3. Format history for context
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
        # Await the async chat_completion call
        response = await client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        content = response.choices[0].message.content

        # Store in Cache
        response_cache[cache_key] = content
        if len(response_cache) > MAX_CACHE_SIZE:
            response_cache.popitem(last=False)

        return content
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
