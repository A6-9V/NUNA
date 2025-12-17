"""
Secure Credential Manager for Trading System
Stores and retrieves credentials using Windows Credential Manager
Falls back to environment variables if Credential Manager unavailable
"""
import os
import json
from typing import Optional, Dict, Any
from pathlib import Path

try:
    import win32cred
    import pywintypes
    WIN32_AVAILABLE = True
except ImportError:
    WIN32_AVAILABLE = False


class CredentialManager:
    """Manages secure credential storage and retrieval"""
    
    def __init__(self, credential_prefix: str = "TradingBridge_"):
        """
        Initialize CredentialManager
        
        Args:
            credential_prefix: Prefix for credential names in Windows Credential Manager
        """
        self.prefix = credential_prefix
        self.config_path = Path(__file__).parent.parent.parent / "config"
        self.config_path.mkdir(parents=True, exist_ok=True)
    
    def get_credential(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """
        Get credential value from Windows Credential Manager or environment
        
        Args:
            key: Credential key name
            default: Default value if not found
            
        Returns:
            Credential value or default
        """
        credential_name = f"{self.prefix}{key}"
        
        # Try Windows Credential Manager first
        if WIN32_AVAILABLE:
            try:
                credential = win32cred.CredRead(credential_name, win32cred.CRED_TYPE_GENERIC, 0)
                if credential:
                    return credential['CredentialBlob'].decode('utf-8')
            except pywintypes.error:
                # Credential not found, continue to fallback
                pass
        
        # Fallback to environment variable
        env_key = credential_name.replace('-', '_').upper()
        value = os.getenv(env_key)
        if value:
            return value
        
        # Fallback to local config file (last resort, must be gitignored)
        config_file = self.config_path / f"{key}.key"
        if config_file.exists():
            try:
                return config_file.read_text(encoding='utf-8').strip()
            except Exception:
                pass
        
        return default
    
    def store_credential(self, key: str, value: str) -> bool:
        """
        Store credential in Windows Credential Manager
        
        Args:
            key: Credential key name
            value: Credential value to store
            
        Returns:
            True if successful, False otherwise
        """
        credential_name = f"{self.prefix}{key}"
        
        if not WIN32_AVAILABLE:
            # Fallback: store in environment variable (session only)
            env_key = credential_name.replace('-', '_').upper()
            os.environ[env_key] = value
            return True
        
        try:
            credential = {
                'Type': win32cred.CRED_TYPE_GENERIC,
                'TargetName': credential_name,
                'UserName': os.getenv('USERNAME', 'TradingSystem'),
                'CredentialBlob': value.encode('utf-8'),
                'Comment': f'Trading system credential for {key}',
                'Persist': win32cred.CRED_PERSIST_LOCAL_MACHINE
            }
            win32cred.CredWrite(credential, 0)
            return True
        except Exception:
            return False
    
    def delete_credential(self, key: str) -> bool:
        """
        Delete credential from Windows Credential Manager
        
        Args:
            key: Credential key name
            
        Returns:
            True if successful, False otherwise
        """
        credential_name = f"{self.prefix}{key}"
        
        if not WIN32_AVAILABLE:
            return False
        
        try:
            win32cred.CredDelete(credential_name, win32cred.CRED_TYPE_GENERIC, 0)
            return True
        except pywintypes.error:
            return False
    
    def get_broker_config(self, broker_name: str) -> Optional[Dict[str, Any]]:
        """
        Get broker configuration securely
        
        Args:
            broker_name: Name of the broker (e.g., 'EXNESS')
            
        Returns:
            Broker configuration dictionary or None
        """
        # Try to load from config file (gitignored)
        config_file = self.config_path / "brokers.json"
        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    configs = json.load(f)
                    brokers = configs.get('brokers', [])
                    for broker in brokers:
                        if broker.get('name', '').upper() == broker_name.upper():
                            # Replace credentials with values from Credential Manager
                            config = broker.copy()
                            if 'api_key' in config:
                                api_key = self.get_credential(f"{broker_name}_API_KEY")
                                if api_key:
                                    config['api_key'] = api_key
                            if 'api_secret' in config:
                                api_secret = self.get_credential(f"{broker_name}_API_SECRET")
                                if api_secret:
                                    config['api_secret'] = api_secret
                            return config
            except Exception:
                pass
        
        return None
    
    def list_credentials(self) -> list:
        """
        List all stored credentials (for debugging, be careful with output)
        
        Returns:
            List of credential names
        """
        credentials = []
        
        if WIN32_AVAILABLE:
            try:
                # Note: This is a simplified approach
                # In production, you might want to maintain a registry of credential names
                pass
            except Exception:
                pass
        
        return credentials


# Convenience functions
_credential_manager = None

def get_credential_manager() -> CredentialManager:
    """Get singleton instance of CredentialManager"""
    global _credential_manager
    if _credential_manager is None:
        _credential_manager = CredentialManager()
    return _credential_manager

def get_credential(key: str, default: Optional[str] = None) -> Optional[str]:
    """Convenience function to get credential"""
    return get_credential_manager().get_credential(key, default)

def store_credential(key: str, value: str) -> bool:
    """Convenience function to store credential"""
    return get_credential_manager().store_credential(key, value)

