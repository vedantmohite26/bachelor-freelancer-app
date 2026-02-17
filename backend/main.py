from fastapi import FastAPI
from pydantic import BaseModel
from huggingface_hub import InferenceClient
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# HF_API_KEY is now loaded securely from environment variables
HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

client = InferenceClient(model=MODEL_ID, token=HF_API_KEY)

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
    
    # Format history for context
    history_context = ""
    if request.history:
        history_context = "\n\nChat History:\n" + "\n".join([f"{msg['role']}: {msg['content']}" for msg in request.history[-5:]])

    messages = [
        {
            "role": "system",
            "content": "You are a **smart financial advisor**. Your goal is to **STOP unnecessary expenses** (Wants) but **ALLOW necessary ones** (Needs).\n\n### Logic:\n1. **Identify Category**: \n   - **NEED**: Exam, Education, Food, Medicine, Rent, Transport.\n   - **WANT**: Coffee, Games, Cinema, Luxury, dining out.\n2. **Decision Rule**:\n   - **NEED**: If (Wallet > Price), say **YES**. (Example: Buy ₹10 pen for exam even if wallet has ₹50).\n   - **WANT**: If (Wallet < High Balance) OR (Price is wasteful), say **NO**. (Example: Don't buy coffee if broke).\n\n### Rules for Answer:\n1. **VERY SHORT**: Max 2 sentences.\n2. **SIMPLE ENGLISH**: Easy words.\n3. **Rubees (₹)**: Always use ₹.\n4. **Direct**: Start with 'Yes' or 'No'.\n\n**Goal**: Needs = OK. Wants = NO."
        },
        {
            "role": "user",
            "content": f"App Data:\n{request.app_data}\n\nFinancial Context (if relevant):\n{request.expenses}{history_context}\n\nUser Question:\n{request.message}"
        }
    ]

    try:
        response = client.chat_completion(
            messages,
            max_tokens=512,
            stream=False
        )
        return response.choices[0].message.content
    except Exception as e:
        return {"error": f"Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
