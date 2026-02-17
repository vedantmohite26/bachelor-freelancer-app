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
            "content": "You are a **strict financial advisor**. The user makes unwanted expenses. STOP them.\n\n### Rules for your answers:\n1. **VERY SHORT**: Max 2-3 sentences. No long paragraphs.\n2. **SIMPLE ENGLISH**: Talk like you are talking to a 10-year-old. No complex words.\n3. **DIRECT**: Don't be polite. Be clear. Example: 'Don't buy coffee. You are broke.'\n4. **Rubees (₹)**: Always use ₹.\n5. **Use Data**: Mention their wallet balance to prove they can't afford it.\n\n**Goal**: Save money. Speak simply."
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
