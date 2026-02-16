# Admin Scripts

This directory contains administrative scripts for managing the Unnati Freelancer database.

## Setup

1. **Install dependencies**:

   ```bash
   cd scripts
   npm install
   ```

2. **Firebase Service Account Key**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file as `firebase-service-account.json` in the project root (NOT in this scripts folder)
   - **IMPORTANT**: This file contains sensitive credentials. Never commit it to version control!

## Delete User Data

Completely removes all data associated with a user email from Firestore and Firebase Authentication.

### Usage

```bash
node delete_user_data.js <email>
```

### Example

```bash
node delete_user_data.js mohitevedant2603@gmail.com
```

### What Gets Deleted

The script removes:

- ✅ User profile from `users` collection
- ✅ User subcollections (friends, friend_requests, notifications)
- ✅ All jobs posted by the user
- ✅ All job applications made by the user
- ✅ All job applications to jobs posted by the user
- ✅ All chats involving the user (including messages)
- ✅ All notifications sent to the user
- ✅ User's friendships in other users' profiles
- ✅ Email lookup entry
- ✅ Leaderboard entry (if exists)
- ✅ Firebase Authentication account

### Safety Features

- **Confirmation Required**: You must type "DELETE" to confirm
- **Detailed Logging**: Shows exactly what is being deleted
- **Error Handling**: Gracefully handles missing data
- **Batch Processing**: Efficiently handles large datasets

### Notes

- The operation is **irreversible**
- Make sure you have a backup if needed
- The script requires Firebase Admin privileges
