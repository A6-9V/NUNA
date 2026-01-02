"""
MQL.io Operations Manager
Manages MQL5 operations and state
"""
import logging
from typing import Dict, List, Optional, Any
from pathlib import Path
import json

logger = logging.getLogger(__name__)


class MQLIOOperationsManager:
    """
    Operations Manager for MQL.io
    Handles MQL5 operations, state management, and coordination
    """
    
    MAX_OPERATIONS_IN_FILE = 1000
    
    def __init__(self, data_dir: Optional[Path] = None):
        """
        Initialize operations manager
        
        Args:
            data_dir: Directory for operation data storage
        """
        self.data_dir = data_dir or Path(__file__).parent.parent.parent / "data" / "mql_io"
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # State files
        self.ea_state_file = self.data_dir / "ea_state.json"
        self.operations_file = self.data_dir / "operations.json"
        
        # Load state
        self.ea_state = self._load_ea_state()
        self.operations = self._load_operations()
        
        logger.info("MQL.io Operations Manager initialized")
    
    def _load_ea_state(self) -> Dict[str, Any]:
        """Load Expert Advisor state"""
        try:
            if self.ea_state_file.exists():
                with open(self.ea_state_file, 'r') as f:
                    return json.load(f)
            return {}
        except Exception as e:
            logger.error(f"Failed to load EA state: {e}")
            return {}
    
    def _save_ea_state(self):
        """Save Expert Advisor state"""
        try:
            with open(self.ea_state_file, 'w') as f:
                json.dump(self.ea_state, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save EA state: {e}")
    
    def _load_operations(self) -> List[Dict[str, Any]]:
        """Load operations history"""
        try:
            if self.operations_file.exists():
                with open(self.operations_file, 'r') as f:
                    return json.load(f)
            return []
        except Exception as e:
            logger.error(f"Failed to load operations: {e}")
            return []
    
    def _save_operations(self):
        """Save operations history"""
        try:
            with open(self.operations_file, 'w') as f:
                json.dump(self.operations[-self.MAX_OPERATIONS_IN_FILE:], f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save operations: {e}")
    
    def register_ea(self, ea_name: str, config: Dict[str, Any]) -> bool:
        """
        Register an Expert Advisor
        
        Args:
            ea_name: Name of the EA
            config: EA configuration
            
        Returns:
            Success status
        """
        try:
            from datetime import datetime
            
            self.ea_state[ea_name] = {
                "name": ea_name,
                "config": config,
                "status": "registered",
                "registered_at": datetime.now().isoformat()
            }
            self._save_ea_state()
            logger.info(f"Registered EA: {ea_name}")
            return True
        except Exception as e:
            logger.error(f"Failed to register EA: {e}")
            return False
    
    def update_ea_status(self, ea_name: str, status: str, details: Optional[Dict] = None) -> bool:
        """
        Update Expert Advisor status
        
        Args:
            ea_name: Name of the EA
            status: New status
            details: Additional details
            
        Returns:
            Success status
        """
        try:
            if ea_name not in self.ea_state:
                logger.warning(f"EA not registered: {ea_name}")
                return False
            
            self.ea_state[ea_name]["status"] = status
            if details:
                self.ea_state[ea_name]["details"] = details
            
            self._save_ea_state()
            logger.info(f"Updated EA status: {ea_name} -> {status}")
            return True
        except Exception as e:
            logger.error(f"Failed to update EA status: {e}")
            return False
    
    def get_ea_state(self, ea_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Get Expert Advisor state
        
        Args:
            ea_name: Specific EA name, or None for all
            
        Returns:
            EA state
        """
        if ea_name:
            return self.ea_state.get(ea_name, {})
        return self.ea_state
    
    def log_operation(self, operation_type: str, details: Dict[str, Any]) -> bool:
        """
        Log an operation
        
        Args:
            operation_type: Type of operation
            details: Operation details
            
        Returns:
            Success status
        """
        try:
            from datetime import datetime
            
            operation = {
                "type": operation_type,
                "timestamp": datetime.now().isoformat(),
                "details": details
            }
            
            self.operations.append(operation)
            self._save_operations()
            
            return True
        except Exception as e:
            logger.error(f"Failed to log operation: {e}")
            return False
    
    def get_operations(self, operation_type: Optional[str] = None, limit: int = 100) -> List[Dict[str, Any]]:
        """
        Get operations history
        
        Args:
            operation_type: Filter by operation type
            limit: Maximum number of operations to return
            
        Returns:
            Operations list
        """
        operations = self.operations
        
        if operation_type:
            operations = [op for op in operations if op.get("type") == operation_type]
        
        return operations[-limit:]
    
    def cleanup_old_operations(self, days: int = 30) -> int:
        """
        Cleanup old operations
        
        Args:
            days: Number of days to retain
            
        Returns:
            Number of operations removed
        """
        try:
            from datetime import datetime, timedelta
            
            cutoff = datetime.now() - timedelta(days=days)
            cutoff_str = cutoff.isoformat()
            
            initial_count = len(self.operations)
            self.operations = [
                op for op in self.operations
                if op.get("timestamp", "") > cutoff_str
            ]
            
            removed = initial_count - len(self.operations)
            if removed > 0:
                self._save_operations()
                logger.info(f"Cleaned up {removed} old operations")
            
            return removed
        except Exception as e:
            logger.error(f"Failed to cleanup operations: {e}")
            return 0
