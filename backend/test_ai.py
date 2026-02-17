import requests
try:
    response = requests.post(
        'http://localhost:8000/finance-ai',
        json={'message': 'I spend too much on food.', 'expenses': 'Food: $500, Rent: $1000'}
    )
    print(response.text)
except Exception as e:
    print(e)
