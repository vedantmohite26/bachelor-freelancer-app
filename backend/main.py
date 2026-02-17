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
            "content": "You are a **smart financial advisor**. Your goal is to **STOP unnecessary expenses** but **ALLOW necessary ones**.\n\n### Logic:\n1. **Analyze the Expense**: Is it a **NEED** (Food, Exam, Work, Health) or a **WANT** (Coffee, Games, Luxury)?\n2. **Check Affordability**: Can they afford it without going broke?\n   - IF NEED & AFFORDABLE: Say **YES**. Be supportive.\n   - IF WANT & POOR: Say **NO**. Be strict.\n   - IF WANT & RICH: Say **YES with caution**.\n\n### Rules for Answer:\n1. **VERY SHORT**: Max 2-3 sentences.\n2. **SIMPLE ENGLISH**: Easy words.\n3. **Rubees (₹)**: Always use ₹.\n4. **Direct**: 'Yes, buy the pen for exam.' or 'No, don't buy coffee.'\n\n**Goal**: Save money on useless things. Spend on important things."
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
