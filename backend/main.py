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

# Use AsyncInferenceClient for non-blocking I/O
client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

# LRU Cache implementation for AI responses
# Capacity: 100 entries
AI_CACHE = OrderedDict()
CACHE_CAPACITY = 100

def get_cache_key(request: 'FinanceRequest') -> str:
    """Generate a unique MD5 hash for the request to use as a cache key."""
    payload = {
        "message": request.message,
        "expenses": request.expenses,
        "history": request.history,
        "app_data": request.app_data
    }
    payload_str = json.dumps(payload, sort_keys=True)
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
    print(f"Received request: {request.message}")
    
    # Check cache first
    cache_key = get_cache_key(request)
    if cache_key in AI_CACHE:
        print("Cache Hit! Returning cached response.")
        # Move to end (LRU)
        AI_CACHE.move_to_end(cache_key)
        return AI_CACHE[cache_key]

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
        # Check for mock scenario (no API key)
        if not HF_API_KEY or HF_API_KEY == "dummy":
            # For testing/local dev without key
            mock_response = "I'm your big brother. I see your request, but I need a real API key to give you proper advice. For now, just save your money! 💰"
            # Cache the mock response too for consistent performance testing
            AI_CACHE[cache_key] = mock_response
            if len(AI_CACHE) > CACHE_CAPACITY:
                AI_CACHE.popitem(last=False)
            return mock_response

        response = await client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        ai_content = response.choices[0].message.content

        # Store in cache
        AI_CACHE[cache_key] = ai_content
        if len(AI_CACHE) > CACHE_CAPACITY:
            AI_CACHE.popitem(last=False)

        return ai_content
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
