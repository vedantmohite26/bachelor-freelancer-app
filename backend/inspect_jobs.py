import firebase_admin
from firebase_admin import credentials, firestore
import os

# Initialize Firebase (assuming creds are set up or using default if emulators/local)
# If you don't have a service account key file, this might fail unless authenticated via CLI.
# Using default credentials which works if 'gbert auth login' or similar was used,
# or if running in an environment with credentials.
try:
    if not firebase_admin._apps:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {
            'projectId': 'unnati-freelance',
        })
    db = firestore.client()
    
    print("--- Checking Completed Jobs ---")
    # Get all jobs with status 'completed'
    jobs_ref = db.collection('jobs')
    query = jobs_ref.where('status', '==', 'completed').limit(10)
    results = query.stream()
    
    count = 0
    for doc in results:
        data = doc.to_dict()
        print(f"Job ID: {doc.id}")
        print(f"  Status: {data.get('status')}")
        print(f"  Assigned Helper ID: {data.get('assignedHelperId')}")
        print(f"  Completed At: {data.get('completedAt')}")
        print(f"  Title: {data.get('title')}")
        print("-" * 20)
        count += 1
        
    if count == 0:
        print("No jobs found with status='completed'.")
        
        # Check for other statuses that might mean completed
        print("\n--- Checking for other statuses ---")
        all_jobs = jobs_ref.limit(20).stream()
        for doc in all_jobs:
            data = doc.to_dict()
            status = data.get('status')
            title = data.get('title')
            helper = data.get('assignedHelperId')
            if status not in ['open', 'in_progress', 'assigned']:
                print(f"Job {doc.id} ({title}): status='{status}', helper='{helper}'")

except Exception as e:
    print(f"Error: {e}")
