#!/usr/bin/env python3
"""
Generate platform config files from a local .env file.

Usage:
  python scripts/generate_configs.py

This will read `.env` in the repo root and create:
 - `android/app/src/main/res/values/secrets.xml` (Google Maps key)
 - `admin-dashboard/admin-config.js` (browser config for admin dashboard)

Do NOT commit your `.env` or the generated files. `.env` should be listed in .gitignore.
"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
ENV_PATH = os.path.join(ROOT, '.env')

def read_env(path):
    env = {}
    if not os.path.exists(path):
        print('No .env found at', path)
        return env
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, v = line.split('=', 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    return env

def write_android_secrets(env):
    key = env.get('GOOGLE_MAPS_KEY', '')
    if not key:
        print('No GOOGLE_MAPS_KEY in .env; skipping android secrets generation')
        return
    out_dir = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', 'values')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'secrets.xml')
    content = f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Generated from .env; do NOT commit this file -->
    <string name="google_maps_key">{key}</string>
</resources>
'''
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Wrote', out_path)

def write_admin_config(env):
    api_key = env.get('FIREBASE_API_KEY', '')
    auth_domain = env.get('FIREBASE_AUTH_DOMAIN', '')
    project_id = env.get('FIREBASE_PROJECT_ID', '')
    storage_bucket = env.get('FIREBASE_STORAGE_BUCKET', '')
    messaging_sender_id = env.get('FIREBASE_MESSAGING_SENDER_ID', '')
    app_id = env.get('FIREBASE_APP_ID', '')
    measurement_id = env.get('FIREBASE_MEASUREMENT_ID', '')

    if not api_key:
        print('No FIREBASE_API_KEY in .env; skipping admin-dashboard config generation')
        return

    out_dir = os.path.join(ROOT, 'admin-dashboard')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'admin-config.js')
    content = f'''// Generated from .env; do NOT commit this file.
window.FIREBASE_CONFIG = {{
  apiKey: "{api_key}",
  authDomain: "{auth_domain}",
  projectId: "{project_id}",
  storageBucket: "{storage_bucket}",
  messagingSenderId: "{messaging_sender_id}",
  appId: "{app_id}",
  measurementId: "{measurement_id}"
}};
'''
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Wrote', out_path)

def main():
    env = read_env(ENV_PATH)
    if not env:
        print('Please create a .env file (copy .env.example) with your keys and re-run this script.')
        sys.exit(1)
    write_android_secrets(env)
    write_admin_config(env)

if __name__ == '__main__':
    main()
