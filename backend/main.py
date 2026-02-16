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

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
def finance_ai(request: FinanceRequest):
    print(f"Received request: {request.message}")
    messages = [
        {
            "role": "system",
            "content": "You are a professional personal finance assistant. Give practical and realistic financial advice."
        },
        {
            "role": "user",
            "content": f"Analyze this user data:\n{request.expenses}\n\nUser Question:\n{request.message}"
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
