"""
MQL.io Service
Main service for MQL5 operations management
"""
import logging
import time
import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime
import threading

logger = logging.getLogger(__name__)


class MQLIOService:
    """
    MQL.io Service for managing MQL5 operations
    
    Features:
    - Expert Advisor management
    - Script execution monitoring
    - Indicator status tracking
    - Real-time operation monitoring
    - Configuration management
    """
    
    def __init__(self, bridge=None, config_path: Optional[Path] = None):
        """
        Initialize MQL.io service
        
        Args:
            bridge: MQL5 bridge instance for communication
            config_path: Path to MQL.io configuration file
        """
        self.bridge = bridge
        self.config_path = config_path or Path(__file__).parent.parent.parent / "config" / "mql_io.json"
        self.config = self._load_config()
        
        # Service state
        self.running = False
        self.monitor_thread = None
        
        # Operation tracking
        self.expert_advisors = {}  # EA status and info
        self.scripts = {}  # Script execution history
        self.indicators = {}  # Indicator status
        self.operations_log = []  # Operation history
        
        logger.info("MQL.io Service initialized")
    
    def _load_config(self) -> Dict[str, Any]:
        """Load MQL.io configuration"""
        try:
            if self.config_path.exists():
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                    logger.info(f"Loaded MQL.io config from {self.config_path}")
                    return config
            else:
                # Default configuration
                default_config = {
                    "monitor_interval": 10,
                    "log_retention_days": 30,
                    "max_operations_log": 1000,
                    "auto_restart_eas": False,
                    "enabled_features": {
                        "ea_monitoring": True,
                        "script_tracking": True,
                        "indicator_monitoring": True,
                        "auto_recovery": False
                    }
                }
                logger.info("Using default MQL.io configuration")
                return default_config
        except Exception as e:
            logger.error(f"Failed to load MQL.io config: {e}")
            return {}
    
    def start(self):
        """Start MQL.io service"""
        if self.running:
            logger.warning("MQL.io service already running")
            return
        
        logger.info("Starting MQL.io service...")
        self.running = True
        
        # Start monitoring thread
        self.monitor_thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self.monitor_thread.start()
        
        logger.info("MQL.io service started")
    
    def stop(self):
        """Stop MQL.io service"""
        logger.info("Stopping MQL.io service...")
        self.running = False
        
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
        
        logger.info("MQL.io service stopped")
    
    def _monitor_loop(self):
        """Main monitoring loop"""
        monitor_interval = self.config.get("monitor_interval", 10)
        
        while self.running:
            try:
                # Monitor Expert Advisors
                if self.config.get("enabled_features", {}).get("ea_monitoring", True):
                    self._monitor_expert_advisors()
                
                # Monitor Scripts
                if self.config.get("enabled_features", {}).get("script_tracking", True):
                    self._monitor_scripts()
                
                # Monitor Indicators
                if self.config.get("enabled_features", {}).get("indicator_monitoring", True):
                    self._monitor_indicators()
                
                # Cleanup old logs
                self._cleanup_old_logs()
                
                time.sleep(monitor_interval)
                
            except Exception as e:
                logger.error(f"Monitor loop error: {e}")
                time.sleep(monitor_interval)
    
    def _monitor_expert_advisors(self):
        """Monitor Expert Advisors status"""
        try:
            if self.bridge:
                # Query EAs through bridge
                ea_status = self._query_ea_status()
                self.expert_advisors.update(ea_status)
                
                # Log any status changes
                for ea_name, status in ea_status.items():
                    if status.get("status") == "error":
                        self._log_operation(f"EA Error: {ea_name}", "ERROR")
                    elif status.get("status") == "stopped":
                        if self.config.get("auto_restart_eas", False):
                            self._restart_ea(ea_name)
        except Exception as e:
            logger.error(f"EA monitoring error: {e}")
    
    def _monitor_scripts(self):
        """Monitor script executions"""
        try:
            # Track script execution history
            # Scripts typically run once and complete
            pass
        except Exception as e:
            logger.error(f"Script monitoring error: {e}")
    
    def _monitor_indicators(self):
        """Monitor indicators status"""
        try:
            # Monitor indicator calculations and status
            pass
        except Exception as e:
            logger.error(f"Indicator monitoring error: {e}")
    
    def _query_ea_status(self) -> Dict[str, Any]:
        """Query Expert Advisor status from MQL5"""
        # Placeholder - would query through bridge
        return {}
    
    def _restart_ea(self, ea_name: str):
        """Restart an Expert Advisor"""
        logger.info(f"Restarting EA: {ea_name}")
        self._log_operation(f"Restarting EA: {ea_name}", "RESTART")
        # Placeholder - would send restart command through bridge
    
    def _log_operation(self, message: str, operation_type: str):
        """Log an operation"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "type": operation_type,
            "message": message
        }
        
        self.operations_log.append(log_entry)
        
        # Trim log if too large
        max_log = self.config.get("max_operations_log", 1000)
        if len(self.operations_log) > max_log:
            self.operations_log = self.operations_log[-max_log:]
        
        logger.info(f"[{operation_type}] {message}")
    
    def _cleanup_old_logs(self):
        """Cleanup old operation logs"""
        retention_days = self.config.get("log_retention_days", 30)
        cutoff_time = datetime.now().timestamp() - (retention_days * 86400)
        
        # Convert cutoff to ISO format for string comparison (more efficient)
        cutoff_iso = datetime.fromtimestamp(cutoff_time).isoformat()
        
        # Filter logs using string comparison
        self.operations_log = [
            log for log in self.operations_log
            if log.get("timestamp", "") > cutoff_iso
        ]
    
    def get_status(self) -> Dict[str, Any]:
        """Get MQL.io service status"""
        return {
            "running": self.running,
            "expert_advisors": len(self.expert_advisors),
            "scripts": len(self.scripts),
            "indicators": len(self.indicators),
            "operations_logged": len(self.operations_log),
            "config": self.config
        }
    
    def get_expert_advisors(self) -> Dict[str, Any]:
        """Get Expert Advisors status"""
        return self.expert_advisors
    
    def get_operations_log(self, limit: int = 100) -> List[Dict[str, Any]]:
        """Get recent operations log"""
        return self.operations_log[-limit:]
    
    def execute_script(self, script_name: str, parameters: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Execute an MQL5 script
        
        Args:
            script_name: Name of the script to execute
            parameters: Optional parameters for the script
            
        Returns:
            Execution result
        """
        try:
            self._log_operation(f"Executing script: {script_name}", "SCRIPT_EXEC")
            
            # Placeholder - would execute through bridge
            result = {
                "status": "success",
                "script": script_name,
                "timestamp": datetime.now().isoformat()
            }
            
            # Track script execution
            self.scripts[script_name] = result
            
            return result
            
        except Exception as e:
            logger.error(f"Script execution error: {e}")
            return {
                "status": "error",
                "error": str(e)
            }
    
    def get_indicator_value(self, indicator_name: str, symbol: str, timeframe: str) -> Optional[float]:
        """
        Get indicator value
        
        Args:
            indicator_name: Name of the indicator
            symbol: Trading symbol
            timeframe: Chart timeframe
            
        Returns:
            Indicator value or None
        """
        try:
            # Placeholder - would query through bridge
            return None
        except Exception as e:
            logger.error(f"Indicator query error: {e}")
            return None


def main():
    """Main entry point for MQL.io service"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    service = MQLIOService()
    
    try:
        service.start()
        
        # Keep service running
        while service.running:
            time.sleep(1)
            
    except KeyboardInterrupt:
        logger.info("MQL.io service interrupted by user")
    finally:
        service.stop()


if __name__ == "__main__":
    main()
