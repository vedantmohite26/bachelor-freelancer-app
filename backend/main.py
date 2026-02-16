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

@app.post("/finance-ai")
def finance_ai(request: FinanceRequest):
    print(f"Received request: {request.message}")
    prompt = f"""[INST]
    You are a professional personal finance assistant.
    Analyze this user data:
    {request.expenses}

    User Question:
    {request.message}

    Give practical and realistic financial advice.
    [/INST]
    """

    try:
        response = client.text_generation(
            prompt,
            max_new_tokens=512,
            return_full_text=False
        )
        return response
    except Exception as e:
        return {"error": f"Error: {str(e)}"}
