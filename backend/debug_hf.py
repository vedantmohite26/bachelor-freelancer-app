from huggingface_hub import InferenceClient
import os
from dotenv import load_dotenv

load_dotenv()

HF_API_KEY = os.getenv("HF_API_KEY")
MODEL_ID = "mistralai/Mistral-7B-Instruct-v0.2"

client = InferenceClient(model=MODEL_ID, token=HF_API_KEY)

messages_with_system = [
    {
        "role": "system",
        "content": "You are a professional personal finance assistant."
    },
    {
        "role": "user",
        "content": "Hello, help me save money."
    }
]

messages_no_system = [
    {
        "role": "user",
        "content": "You are a professional personal finance assistant. Hello, help me save money."
    }
]

print("Testing with system message...")
try:
    response = client.chat_completion(messages_with_system, max_tokens=100)
    print("Success with system message:", response.choices[0].message.content)
except Exception as e:
    print("Error with system message:", e)

print("\nTesting without system message...")
try:
    response = client.chat_completion(messages_no_system, max_tokens=100)
    print("Success without system message:", response.choices[0].message.content)
except Exception as e:
    print("Error without system message:", e)
