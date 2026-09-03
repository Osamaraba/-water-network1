"""
Data Encryption Service
Yarmouk Water Management Pro
"""
import os
import base64
import hashlib
from typing import Optional
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


class EncryptionService:
    """Service for encrypting and decrypting sensitive data."""
    
    def __init__(self, master_key: Optional[str] = None):
        if master_key:
            self._key = self._derive_key(master_key)
        else:
            # Generate a random key if no master key provided
            self._key = Fernet.generate_key()
        
        self._fernet = Fernet(self._key)
    
    def _derive_key(self, master_key: str) -> bytes:
        """Derive a Fernet key from a master key."""
        salt = b"yarmouk_water_management_salt"  # In production, use a random salt
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(master_key.encode()))
        return key
    
    def encrypt(self, data: str) -> str:
        """Encrypt a string."""
        encrypted = self._fernet.encrypt(data.encode())
        return encrypted.decode()
    
    def decrypt(self, encrypted_data: str) -> str:
        """Decrypt a string."""
        decrypted = self._fernet.decrypt(encrypted_data.encode())
        return decrypted.decode()
    
    def encrypt_dict(self, data: dict) -> str:
        """Encrypt a dictionary (JSON)."""
        import json
        json_str = json.dumps(data, ensure_ascii=False)
        return self.encrypt(json_str)
    
    def decrypt_dict(self, encrypted_data: str) -> dict:
        """Decrypt to a dictionary."""
        import json
        json_str = self.decrypt(encrypted_data)
        return json.loads(json_str)
    
    @staticmethod
    def hash_password(password: str) -> str:
        """Hash a password using SHA-256."""
        return hashlib.sha256(password.encode()).hexdigest()
    
    @staticmethod
    def verify_password(password: str, hashed: str) -> bool:
        """Verify a password against its hash."""
        return hashlib.sha256(password.encode()).hexdigest() == hashed
    
    @staticmethod
    def generate_api_key() -> str:
        """Generate a random API key."""
        return base64.urlsafe_b64encode(os.urandom(32)).decode()


# Global encryption service instance
# In production, load the master key from environment variables
encryption_service = EncryptionService(
    master_key=os.getenv("ENCRYPTION_MASTER_KEY", "yarmouk_default_master_key")
)
