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

client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

# Simple LRU Cache
CACHE_CAPACITY = 100
response_cache = OrderedDict()

def get_cache_key(request_dict: dict) -> str:
    # Create a stable string representation for hashing
    # Sort history and other nested structures if necessary, but here simple json.dumps(sort_keys=True) works
    encoded_str = json.dumps(request_dict, sort_keys=True).encode('utf-8')
    return hashlib.md5(encoded_str).hexdigest()

class FinanceRequest(BaseModel):
    message: str
    expenses: str
    history: list[dict] = []
    app_data: str = ""

@app.get("/")
async def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
async def finance_ai(request: FinanceRequest):
    request_dict = request.model_dump()
    cache_key = get_cache_key(request_dict)

    # Check cache
    if cache_key in response_cache:
        print(f"Cache hit for: {request.message}")
        # Move to end to maintain LRU
        response_cache.move_to_end(cache_key)
        return response_cache[cache_key]

    print(f"Received request: {request.message}")
    
    # Mock response logic if API key is missing for development/testing
    if not HF_API_KEY:
        mock_response = f"Mock response for: {request.message} (₹500). I'm your AI sibling, and I say NO to unnecessary spending! 😤"
        # Store in cache even for mock to test caching layer
        response_cache[cache_key] = mock_response
        if len(response_cache) > CACHE_CAPACITY:
            response_cache.popitem(last=False)
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
        ai_content = response.choices[0].message.content

        # Store in cache
        response_cache[cache_key] = ai_content
        if len(response_cache) > CACHE_CAPACITY:
            response_cache.popitem(last=False)

        return ai_content
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
