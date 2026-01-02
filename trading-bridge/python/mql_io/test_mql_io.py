"""
MQL.io Service Test Script
Validates all MQL.io components
"""
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from mql_io import MQLIOService, MQLIOAPIHandler, MQLIOOperationsManager


def test_service():
    """Test MQL.io Service"""
    print("\n=== Testing MQL.io Service ===")
    
    service = MQLIOService()
    print("✓ Service initialized")
    
    status = service.get_status()
    assert not status['running'], "Service should not be running initially"
    print("✓ Service status correct")
    
    # Test configuration
    assert 'monitor_interval' in service.config
    assert 'enabled_features' in service.config
    print("✓ Configuration loaded")
    
    return service


def test_api_handler(service):
    """Test API Handler"""
    print("\n=== Testing API Handler ===")
    
    api = MQLIOAPIHandler(service)
    print("✓ API Handler initialized")
    
    # Test status endpoint
    response = api.handle_get_status()
    assert response['success'] == True
    assert 'data' in response
    print("✓ GET /status working")
    
    # Test EA endpoint
    response = api.handle_get_expert_advisors()
    assert response['success'] == True
    assert 'data' in response
    print("✓ GET /expert-advisors working")
    
    # Test operations log endpoint
    response = api.handle_get_operations_log(limit=10)
    assert response['success'] == True
    assert 'data' in response
    print("✓ GET /operations-log working")
    
    # Test script execution
    response = api.handle_execute_script("TestScript", {"param": "value"})
    assert response['success'] == True
    print("✓ POST /execute-script working")
    
    # Test route request
    response = api.route_request("/status", "GET")
    assert response['success'] == True
    print("✓ Request routing working")


def test_operations_manager():
    """Test Operations Manager"""
    print("\n=== Testing Operations Manager ===")
    
    manager = MQLIOOperationsManager()
    print("✓ Operations Manager initialized")
    
    # Test EA registration
    result = manager.register_ea("TestEA1", {"symbol": "EURUSD", "timeframe": "H1"})
    assert result == True
    print("✓ EA registration working")
    
    # Test EA status update
    result = manager.update_ea_status("TestEA1", "running", {"msg": "test"})
    assert result == True
    print("✓ EA status update working")
    
    # Test get EA state
    state = manager.get_ea_state("TestEA1")
    assert state['status'] == 'running'
    print("✓ Get EA state working")
    
    # Test operation logging
    result = manager.log_operation("TEST", {"action": "test_operation"})
    assert result == True
    print("✓ Operation logging working")
    
    # Test get operations
    ops = manager.get_operations(limit=10)
    assert len(ops) > 0
    print("✓ Get operations working")


def test_integration():
    """Test integration between components"""
    print("\n=== Testing Integration ===")
    
    # Create service
    service = MQLIOService()
    
    # Create operations manager
    ops_manager = MQLIOOperationsManager()
    
    # Create API handler
    api_handler = MQLIOAPIHandler(service)
    
    # Register an EA
    ops_manager.register_ea("IntegrationEA", {"symbol": "GBPUSD"})
    
    # Execute script through API
    response = api_handler.handle_execute_script("IntegrationScript")
    assert response['success'] == True
    
    # Get status through API
    response = api_handler.handle_get_status()
    assert response['success'] == True
    
    print("✓ Integration between components working")


def main():
    """Run all tests"""
    print("=" * 50)
    print("MQL.io Service Test Suite")
    print("=" * 50)
    
    try:
        # Run tests
        service = test_service()
        test_api_handler(service)
        test_operations_manager()
        test_integration()
        
        print("\n" + "=" * 50)
        print("✓ All tests passed!")
        print("=" * 50)
        return 0
        
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
