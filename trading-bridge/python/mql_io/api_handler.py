"""
MQL.io API Handler
Provides API endpoints for MQL5 operations
"""
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime

logger = logging.getLogger(__name__)


class MQLIOAPIHandler:
    """
    API Handler for MQL.io operations
    Provides RESTful interface for MQL5 management
    """
    
    def __init__(self, mql_io_service):
        """
        Initialize API handler
        
        Args:
            mql_io_service: MQLIOService instance
        """
        self.service = mql_io_service
        logger.info("MQL.io API Handler initialized")
    
    def handle_get_status(self) -> Dict[str, Any]:
        """
        Handle GET /status request
        
        Returns:
            Service status information
        """
        try:
            status = self.service.get_status()
            return {
                "success": True,
                "data": status,
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Get status error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def handle_get_expert_advisors(self) -> Dict[str, Any]:
        """
        Handle GET /expert-advisors request
        
        Returns:
            Expert Advisors information
        """
        try:
            eas = self.service.get_expert_advisors()
            return {
                "success": True,
                "data": eas,
                "count": len(eas)
            }
        except Exception as e:
            logger.error(f"Get EAs error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def handle_execute_script(self, script_name: str, parameters: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Handle POST /execute-script request
        
        Args:
            script_name: Name of script to execute
            parameters: Script parameters
            
        Returns:
            Execution result
        """
        try:
            if not script_name:
                return {
                    "success": False,
                    "error": "Script name required"
                }
            
            result = self.service.execute_script(script_name, parameters)
            return {
                "success": True,
                "data": result
            }
        except Exception as e:
            logger.error(f"Execute script error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def handle_get_operations_log(self, limit: int = 100) -> Dict[str, Any]:
        """
        Handle GET /operations-log request
        
        Args:
            limit: Maximum number of log entries to return
            
        Returns:
            Operations log
        """
        try:
            logs = self.service.get_operations_log(limit)
            return {
                "success": True,
                "data": logs,
                "count": len(logs)
            }
        except Exception as e:
            logger.error(f"Get operations log error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def handle_get_indicator(self, indicator_name: str, symbol: str, timeframe: str) -> Dict[str, Any]:
        """
        Handle GET /indicator request
        
        Args:
            indicator_name: Name of the indicator
            symbol: Trading symbol
            timeframe: Chart timeframe
            
        Returns:
            Indicator value
        """
        try:
            if not all([indicator_name, symbol, timeframe]):
                return {
                    "success": False,
                    "error": "indicator_name, symbol, and timeframe required"
                }
            
            value = self.service.get_indicator_value(indicator_name, symbol, timeframe)
            return {
                "success": True,
                "data": {
                    "indicator": indicator_name,
                    "symbol": symbol,
                    "timeframe": timeframe,
                    "value": value
                }
            }
        except Exception as e:
            logger.error(f"Get indicator error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def route_request(self, endpoint: str, method: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Route API request to appropriate handler
        
        Args:
            endpoint: API endpoint
            method: HTTP method (GET, POST, etc.)
            data: Request data
            
        Returns:
            Response data
        """
        try:
            # Route to appropriate handler
            if endpoint == "/status" and method == "GET":
                return self.handle_get_status()
            
            elif endpoint == "/expert-advisors" and method == "GET":
                return self.handle_get_expert_advisors()
            
            elif endpoint == "/execute-script" and method == "POST":
                script_name = data.get("script_name") if data else None
                parameters = data.get("parameters") if data else None
                return self.handle_execute_script(script_name, parameters)
            
            elif endpoint == "/operations-log" and method == "GET":
                limit = data.get("limit", 100) if data else 100
                return self.handle_get_operations_log(limit)
            
            elif endpoint == "/indicator" and method == "GET":
                if not data:
                    return {"success": False, "error": "Missing parameters"}
                return self.handle_get_indicator(
                    data.get("indicator_name"),
                    data.get("symbol"),
                    data.get("timeframe")
                )
            
            else:
                return {
                    "success": False,
                    "error": f"Unknown endpoint: {method} {endpoint}"
                }
                
        except Exception as e:
            logger.error(f"Route request error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
