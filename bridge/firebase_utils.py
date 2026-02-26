import json
import os
from pathlib import Path
from typing import Any, Dict, Optional

import firebase_admin
from .common_utils import eprint
from firebase_admin import credentials, firestore

def load_firebase_config(config_path: str = "firebase-config.json") -> Dict[str, Any]:
    """Loads the Firebase configuration from a JSON file."""
    path = Path(config_path)
    if not path.exists():
        # Try example if real one is missing, but warn
        example_path = path.with_suffix(".example.json")
        if example_path.exists():
            eprint(f"Warning: {config_path} not found. Using {example_path} instead.")
            path = example_path
        else:
            raise FileNotFoundError(f"Firebase config file not found: {config_path}")

    with path.open("r", encoding="utf-8") as f:
        return json.load(f)

def initialize_firebase(service_account_path: Optional[str] = None) -> Any:
    """
    Initializes the Firebase Admin SDK.
    If service_account_path is provided, it uses that service account.
    Otherwise, it attempts to use application default credentials.
    """
    if not firebase_admin._apps:
        if service_account_path and os.path.exists(service_account_path):
            creds = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(creds)
        else:
            # This will work if GOOGLE_APPLICATION_CREDENTIALS is set
            # or if running on GCP/Firebase.
            firebase_admin.initialize_app()
    return firebase_admin.get_app()

def get_firestore_client():
    """Returns a Firestore client instance."""
    initialize_firebase()
    return firestore.client()

if __name__ == "__main__":
    try:
        config = load_firebase_config()
        print("Firebase Configuration loaded successfully:")
        print(json.dumps(config, indent=2))
    except FileNotFoundError as e:
        print(f"Error: {e}")
