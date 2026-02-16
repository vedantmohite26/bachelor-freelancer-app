import requests
import time

BASE_URL = "http://127.0.0.1:5000/api"

def test_flow():
    print("Testing 2FA Flow...")
    
    # 1. Setup 2FA
    print("\n1. Setting up 2FA for 'test@example.com'...")
    try:
        response = requests.post(f"{BASE_URL}/setup-2fa", json={'userEmail': 'test@example.com'})
        if response.status_code != 200:
            print(f"FAILED: Setup 2FA failed with {response.status_code}: {response.text}")
            return
            
        data = response.json()
        secret = data['secret']
        temp_otp = data['tempOtp']
        print(f"SUCCESS: Received secret: {secret}, Temp OTP: {temp_otp}")
        
    except Exception as e:
        print(f"FAILED: Could not connect to backend: {e}")
        return

    # 2. Verify OTP (Valid)
    print(f"\n2. Verifying VALID OTP: {temp_otp}...")
    try:
        response = requests.post(f"{BASE_URL}/verify-otp", json={
            'userSecret': secret,
            'otp': temp_otp
        })
        is_valid = response.json()['valid']
        if is_valid:
             print("SUCCESS: OTP verified as valid.")
        else:
             print("FAILED: OTP verified as INVALID (Expected Valid).")
             
    except Exception as e:
         print(f"FAILED: Verification request failed: {e}")

    # 3. Verify OTP (Invalid)
    invalid_otp = "000000"
    print(f"\n3. Verifying INVALID OTP: {invalid_otp}...")
    try:
        response = requests.post(f"{BASE_URL}/verify-otp", json={
            'userSecret': secret,
            'otp': invalid_otp
        })
        is_valid = response.json()['valid']
        if not is_valid:
             print("SUCCESS: OTP verified as invalid.")
        else:
             print("FAILED: OTP verified as VALID (Expected Invalid).")

    except Exception as e:
         print(f"FAILED: Verification request failed: {e}")

if __name__ == "__main__":
    # Give server a moment to start if run immediately after
    time.sleep(2) 
    test_flow()
