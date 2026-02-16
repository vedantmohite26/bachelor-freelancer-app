from flask import Flask, request, jsonify
import pyotp
import qrcode
import base64
from io import BytesIO

app = Flask(__name__)

# In-memory storage for demonstration (Use a database in production)
# Structure: { 'user_email': 'base32_secret' }
user_secrets = {}

@app.route('/api/setup-2fa', methods=['POST'])
def setup_2fa():
    data = request.json
    user_email = data.get('userEmail')
    
    if not user_email:
        return jsonify({'error': 'User email required'}), 400

    # 1. Generate a random base32 Secret
    secret = pyotp.random_base32()
    user_secrets[user_email] = secret
    
    # 2. Generate Provisioning URI for Authenticator apps
    # Format: otpauth://totp/AppName:UserEmail?secret=SECRET&issuer=AppName
    provisioning_uri = pyotp.totp.TOTP(secret).provisioning_uri(
        name=user_email, 
        issuer_name="Unnati Freelancer"
    )
    
    # 3. Generate Current OTP for immediate testing
    totp = pyotp.TOTP(secret)
    current_otp = totp.now()

    return jsonify({
        'secret': secret,
        'otpAuthUrl': provisioning_uri, # For QR Code generation on frontend if needed or raw data
        'qrCode': provisioning_uri, # The frontend 'qr_flutter' takes the data string
        'tempOtp': current_otp
    })

@app.route('/api/verify-otp', methods=['POST'])
def verify_otp():
    data = request.json
    user_secret = data.get('userSecret')
    otp = data.get('otp')
    
    if not user_secret or not otp:
        return jsonify({'error': 'Secret and OTP required'}), 400
        
    # Verify
    totp = pyotp.TOTP(user_secret)
    is_valid = totp.verify(otp)
    
    return jsonify({'valid': is_valid})

if __name__ == '__main__':
    # Host 0.0.0.0 allows access from outside the container/emulator
    print("Starting OTP Server on 0.0.0.0:5000")
    print("Ensure your Android Emulator can reach this machine (usually 10.0.2.2)")
    app.run(host='0.0.0.0', port=5000, debug=True)
