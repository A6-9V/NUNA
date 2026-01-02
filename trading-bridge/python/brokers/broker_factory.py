"""
Broker Factory
Creates broker instances based on configuration
"""
import json
from typing import Dict, Optional, List
from pathlib import Path

from .base_broker import BaseBroker, BrokerConfig
from .exness_api import ExnessAPI

# Import credential manager
import sys
sys.path.append(str(Path(__file__).parent.parent))
from security.credential_manager import get_credential_manager


class BrokerFactory:
    """Factory for creating broker instances"""
    
    _broker_classes = {
        'EXNESS': ExnessAPI,
        # Add more brokers here as they're implemented
    }
    
    @classmethod
    def create_broker(cls, name: str, config: Optional[BrokerConfig] = None) -> Optional[BaseBroker]:
        """
        Create broker instance
        
        Args:
            name: Broker name (e.g., 'EXNESS')
            config: Broker configuration (optional, will load from file if not provided)
            
        Returns:
            Broker instance or None if not found
        """
        name_upper = name.upper()
        
        if name_upper not in cls._broker_classes:
            return None
        
        # Load config if not provided
        if config is None:
            config = cls._load_broker_config(name_upper)
            if config is None:
                return None
        
        # Get broker class
        broker_class = cls._broker_classes[name_upper]
        
        # Create and return broker instance
        try:
            return broker_class(config)
        except Exception as e:
            print(f"Error creating broker {name}: {e}")
            return None
    
    @classmethod
    def _load_broker_config(cls, broker_name: str) -> Optional[BrokerConfig]:
        """
        Load broker configuration from file
        
        Args:
            broker_name: Broker name
            
        Returns:
            BrokerConfig or None
        """
        cm = get_credential_manager()
        broker_config = cm.get_broker_config(broker_name)
        
        if not broker_config:
            return None
        
        # Create BrokerConfig object
        config = BrokerConfig(
            name=broker_config.get('name', broker_name),
            api_url=broker_config.get('api_url', ''),
            account_id=broker_config.get('account_id', ''),
            api_key=broker_config.get('api_key'),
            api_secret=broker_config.get('api_secret'),
            enabled=broker_config.get('enabled', True),
            rate_limit=broker_config.get('rate_limit')
        )
        
        return config
    
    @classmethod
    def create_all_brokers(cls) -> Dict[str, BaseBroker]:
        """
        Create all configured brokers
        
        Returns:
            Dictionary of broker_name -> broker_instance
        """
        brokers = {}
        cm = get_credential_manager()
        
        # Load broker configs
        config_file = Path(__file__).parent.parent.parent / "config" / "brokers.json"
        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    configs = json.load(f)
                    broker_configs = configs.get('brokers', [])
                    
                    for broker_data in broker_configs:
                        broker_name = broker_data.get('name', '').upper()
                        if broker_name in cls._broker_classes:
                            broker = cls.create_broker(broker_name)
                            if broker:
                                brokers[broker_name] = broker
            except Exception as e:
                print(f"Error loading broker configs: {e}")
        
        return brokers
    
    @classmethod
    def register_broker(cls, name: str, broker_class: type):
        """
        Register a new broker class
        
        Args:
            name: Broker name
            broker_class: Broker class (must extend BaseBroker)
        """
        cls._broker_classes[name.upper()] = broker_class
    
    @classmethod
    def get_available_brokers(cls) -> List[str]:
        """
        Get list of available broker names
        
        Returns:
            List of broker names
        """
        return list(cls._broker_classes.keys())

