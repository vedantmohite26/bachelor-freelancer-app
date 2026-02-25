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

client = AsyncInferenceClient(model=MODEL_ID, token=HF_API_KEY)

# In-memory cache for AI responses
CACHE_CAPACITY = 100
response_cache = OrderedDict()

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
    print(f"App Data: {request.app_data}")  # Debug print
    
    # Generate cache key from request payload
    cache_payload = json.dumps({
        "message": request.message,
        "expenses": request.expenses,
        "history": request.history,
        "app_data": request.app_data
    }, sort_keys=True)
    cache_key = hashlib.md5(cache_payload.encode()).hexdigest()

    # Check cache
    if cache_key in response_cache:
        print("Cache hit! Returning stored response.")
        # Move to end to maintain LRU
        response_cache.move_to_end(cache_key)
        return response_cache[cache_key]

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

    # Mock response for local development if API key is missing
    if not HF_API_KEY:
        msg = request.message.lower()
        if "pen" in msg or "food" in msg:
            result = "Yes, that's a need. Go ahead."
        else:
            result = "No, stop wasting money on unnecessary things! 😡"
    else:
        try:
            response = await client.chat_completion(
                messages,
                max_tokens=512,
                stream=False
            )
            result = response.choices[0].message.content
        except Exception as e:
            return {"error": f"Error: {str(e)}"}

    # Store in cache
    response_cache[cache_key] = result
    if len(response_cache) > CACHE_CAPACITY:
        response_cache.popitem(last=False)

    return result

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
