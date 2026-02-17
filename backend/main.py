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
    history: list[dict] = []  # New optional history field

@app.get("/")
def home():
    return {"status": "online", "message": "Financial Assistant Backend is Running"}

@app.post("/finance-ai")
def finance_ai(request: FinanceRequest):
    print(f"Received request: {request.message}")
    
    # Format history for context
    history_context = ""
    if request.history:
        history_context = "\n\nChat History:\n" + "\n".join([f"{msg['role']}: {msg['content']}" for msg in request.history[-5:]])

    messages = [
        {
            "role": "system",
            "content": "You are a friendly and helpful AI assistant with the personality of Gemini. You are capable of answering ANY question (coding, general knowledge, jokes, life advice, etc.).\n\n- **Financial Context**: The user is in **India**. ALWAYS use **Indian Rupees (₹)** for currency. Do not use dollars ($).\n- If the user asks about money/finance, use the provided financial data to give specific, practical money-saving advice relevant to the Indian market.\n- If the user asks a non-financial question (e.g. 'Tell me a joke', 'What is Python?'), IGNORE the financial data and answer the question directly and creatively.\n- **Clarification**: If you need more information to give a good answer, ASK the user. Don't guess.\n- **Memory**: Use the provided 'Chat History' to understand context (e.g., if user says 'what about 500?', recall what they asked before).\n\nAlways be helpful, genuine, and comprehensive."
        },
        {
            "role": "user",
            "content": f"Financial Context (if relevant):\n{request.expenses}{history_context}\n\nUser Question:\n{request.message}"
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
