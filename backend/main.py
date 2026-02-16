from fastapi import FastAPI
from pydantic import BaseModel
import requests
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_URL = "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2"

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

    payload = {
        "inputs": prompt,
        "parameters": {
            "max_new_tokens": 512,
            "return_full_text": False,
        }
    }

    response = requests.post(
        MODEL_URL,
        headers={
            "Authorization": f"Bearer {HF_API_KEY}",
            "Content-Type": "application/json"
        },
        json=payload
    )

    if response.status_code != 200:
        return {"error": f"Error: {response.text}"}

    result = response.json()
    
    # Hugging Face Inference API returns a list of dictionaries normally
    if isinstance(result, list) and len(result) > 0:
        return result[0]["generated_text"]
    elif isinstance(result, dict) and "error" in result:
        return result["error"]
    else:
        return str(result)
