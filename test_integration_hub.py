#!/usr/bin/env python3
"""
Test script for NUNA MQL5 Integration Hub
Tests the main components without actually starting the servers
"""

import sys
import os
import json
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

def test_imports():
    """Test that all required modules can be imported"""
    print("Testing imports...")
    try:
        import main
        from dotenv import load_dotenv
        from fastapi import FastAPI
        import uvicorn
        print("✓ All imports successful")
        return True
    except ImportError as e:
        print(f"✗ Import error: {e}")
        return False

def test_load_symbols_config():
    """Test symbol configuration loading"""
    print("\nTesting symbol configuration loading...")
    try:
        from main import load_symbols_config
        
        # Set test environment
        os.environ['SYMBOLS'] = 'EURUSD,GBPUSD,USDJPY'
        
        symbols = load_symbols_config()
        
        assert isinstance(symbols, dict), "Symbols should be a dictionary"
        assert len(symbols) >= 3, f"Should have at least 3 symbols, got {len(symbols)}"
        
        # Check structure of a symbol
        for symbol_key in ['EURUSD', 'GBPUSD', 'USDJPY']:
            if symbol_key in symbols:
                symbol_data = symbols[symbol_key]
                assert 'symbol' in symbol_data, "Symbol should have 'symbol' field"
                assert 'enabled' in symbol_data, "Symbol should have 'enabled' field"
                assert 'broker' in symbol_data, "Symbol should have 'broker' field"
                print(f"✓ Loaded {len(symbols)} symbols successfully")
                print(f"  Sample: {list(symbols.keys())[:3]}")
                return True
        
        print(f"⚠ None of the expected symbols found, but got {len(symbols)} symbols")
        return len(symbols) > 0
    except Exception as e:
        print(f"✗ Error loading symbols: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_check_mt5_connection():
    """Test MT5 connection check (won't actually connect)"""
    print("\nTesting MT5 connection check...")
    try:
        from main import check_mt5_connection
        
        # This will return False since we don't have MT5 installed
        result = check_mt5_connection()
        
        print(f"✓ MT5 connection check completed (result: {result})")
        return True
    except Exception as e:
        print(f"✗ Error checking MT5 connection: {e}")
        return False

def test_api_structure():
    """Test that API server function is properly structured"""
    print("\nTesting API server structure...")
    try:
        from main import start_api_server
        
        # Check that function exists and is callable
        assert callable(start_api_server), "start_api_server should be callable"
        
        print("✓ API server function is properly structured")
        return True
    except Exception as e:
        print(f"✗ Error testing API structure: {e}")
        return False

def test_bridge_structure():
    """Test that bridge server functions are properly structured"""
    print("\nTesting bridge server structure...")
    try:
        from main import start_bridge_server, handle_bridge_client
        
        # Check that functions exist and are callable
        assert callable(start_bridge_server), "start_bridge_server should be callable"
        assert callable(handle_bridge_client), "handle_bridge_client should be callable"
        
        print("✓ Bridge server functions are properly structured")
        return True
    except Exception as e:
        print(f"✗ Error testing bridge structure: {e}")
        return False

def test_documentation_exists():
    """Test that documentation files exist"""
    print("\nTesting documentation...")
    try:
        docs = [
            'API_DOCUMENTATION.md',
            'README.md',
            'REPLIT_INTEGRATION.md'
        ]
        
        for doc in docs:
            path = Path(__file__).parent / doc
            assert path.exists(), f"{doc} should exist"
            
        print(f"✓ All {len(docs)} documentation files exist")
        return True
    except Exception as e:
        print(f"✗ Documentation test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("NUNA MQL5 Integration Hub - Component Tests")
    print("=" * 60)
    
    tests = [
        test_imports,
        test_load_symbols_config,
        test_check_mt5_connection,
        test_api_structure,
        test_bridge_structure,
        test_documentation_exists
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"✗ Test crashed: {e}")
            results.append(False)
    
    print("\n" + "=" * 60)
    print("Test Results:")
    print("=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"Passed: {passed}/{total}")
    
    if passed == total:
        print("✓ All tests passed!")
        return 0
    else:
        print(f"✗ {total - passed} test(s) failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())
