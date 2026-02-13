"""
Trading Bridge Service - Connects Docker services to MT5 Terminal
"""
import os
import sys
import json
import logging
import socket
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Setup logging
logging.basicConfig(
    level=os.getenv('LOG_LEVEL', 'INFO'),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def load_symbols_config():
    """
    Load symbols configuration using hybrid approach:
    1. Read SYMBOLS environment variable (comma-separated list)
    2. Load detailed config from symbols.json
    3. Merge: use JSON config if exists, otherwise use env var with defaults
    """
    symbols = {}
    
    # Get symbols from environment variable
    env_symbols_str = os.getenv('SYMBOLS', '')
    env_symbols = [s.strip() for s in env_symbols_str.split(',') if s.strip()]
    
    # Load detailed configuration from JSON
    symbol_config = {}
    symbols_json_path = Path('/app/config/symbols.json')
    if symbols_json_path.exists():
        try:
            with open(symbols_json_path) as f:
                config_data = json.load(f)
                for symbol_entry in config_data.get('symbols', []):
                    symbol_config[symbol_entry['symbol']] = symbol_entry
            logger.info(f"Loaded {len(symbol_config)} symbols from JSON config")
        except Exception as e:
            logger.warning(f"Could not load symbols.json: {e}")
    
    # Merge: prioritize JSON config, fallback to env var with defaults
    all_symbols = set(env_symbols)
    if symbol_config:
        all_symbols.update(symbol_config.keys())
    
    for symbol in all_symbols:
        if symbol in symbol_config:
            # Use detailed JSON config
            symbols[symbol] = symbol_config[symbol]
        elif symbol in env_symbols:
            # Create default config from env var
            symbols[symbol] = {
                'symbol': symbol,
                'broker': os.getenv('EXNESS_SERVER', 'EXNESS_DEMO'),
                'enabled': True,
                'risk_percent': 1.0,
                'max_positions': 1,
                'min_lot_size': 0.01,
                'max_lot_size': 10.0,
                'description': f"{symbol} (from environment)"
            }
    
    logger.info(f"Total symbols configured: {len(symbols)}")
    return symbols

def check_mt5_connection():
    """Check if MT5 terminal directory is accessible"""
    mt5_path = os.getenv('MT5_TERMINAL_PATH', '/mt5')
    if os.path.exists(mt5_path):
        logger.info(f"MT5 terminal path accessible: {mt5_path}")
        return True
    else:
        logger.warning(f"MT5 terminal path not found: {mt5_path}")
        return False

def handle_bridge_client(client_socket, address):
    """Handle individual bridge client connections"""
    try:
        logger.info(f"New bridge connection from {address}")
        
        # Set socket timeout
        client_socket.settimeout(30.0)
        
        # Send welcome message
        from datetime import datetime
        welcome = {
            "status": "connected",
            "service": "NUNA MQL5 Bridge",
            "version": "2.0.0",
            "timestamp": datetime.utcnow().isoformat()
        }
        client_socket.send(json.dumps(welcome).encode() + b"\n")
        
        # Handle client requests
        while True:
            try:
                data = client_socket.recv(4096)
                if not data:
                    logger.info(f"Client {address} disconnected")
                    break
                
                # Parse and handle request
                try:
                    request = json.loads(data.decode().strip())
                    logger.debug(f"Received request from {address}: {request}")
                    
                    # Process request based on command
                    command = request.get('command', 'unknown')
                    response = {"status": "ok", "command": command}
                    
                    if command == 'ping':
                        response['message'] = 'pong'
                    elif command == 'status':
                        response['mt5_connected'] = check_mt5_connection()
                        response['symbols_count'] = len(load_symbols_config())
                    elif command == 'symbols':
                        response['symbols'] = list(load_symbols_config().keys())
                    else:
                        response['status'] = 'unknown_command'
                        response['message'] = f"Unknown command: {command}"
                    
                    # Send response
                    client_socket.send(json.dumps(response).encode() + b"\n")
                    
                except json.JSONDecodeError:
                    error_response = {
                        "status": "error",
                        "message": "Invalid JSON format"
                    }
                    client_socket.send(json.dumps(error_response).encode() + b"\n")
                    
            except socket.timeout:
                logger.warning(f"Client {address} connection timeout")
                break
            except Exception as e:
                logger.error(f"Error processing client request: {e}")
                break
                
    except Exception as e:
        logger.error(f"Error handling bridge client {address}: {e}")
    finally:
        try:
            client_socket.close()
            logger.info(f"Closed connection from {address}")
        except:
            pass

def start_bridge_server():
    """Start the enhanced bridge server with connection pooling"""
    bridge_port = int(os.getenv('BRIDGE_PORT', 5555))
    
    # Create socket server
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server_socket.bind(('0.0.0.0', bridge_port))
        server_socket.listen(10)  # Increased backlog
        logger.info(f"Enhanced bridge server listening on port {bridge_port}")
        logger.info("Supported commands: ping, status, symbols")
        
        import threading
        active_connections = []
        
        while True:
            try:
                client_socket, address = server_socket.accept()
                
                # Handle client in a separate thread
                client_thread = threading.Thread(
                    target=handle_bridge_client,
                    args=(client_socket, address),
                    daemon=True
                )
                client_thread.start()
                active_connections.append(client_thread)
                
                # Clean up finished threads
                active_connections = [t for t in active_connections if t.is_alive()]
                logger.debug(f"Active bridge connections: {len(active_connections)}")
                
            except Exception as e:
                logger.error(f"Error accepting client connection: {e}")
                
    except Exception as e:
        logger.error(f"Bridge server error: {e}")
    finally:
        try:
            server_socket.close()
            logger.info("Bridge server shut down")
        except:
            pass

def start_api_server():
    """Start the FastAPI server with enhanced endpoints"""
    import uvicorn
    from fastapi import FastAPI, HTTPException
    from fastapi.responses import JSONResponse
    from datetime import datetime
    import platform
    
    app = FastAPI(
        title="NUNA MQL5 Integration Hub API",
        description="Advanced MetaTrader 5 integration API for NUNA trading system",
        version="2.0.0",
        docs_url="/docs",
        redoc_url="/redoc"
    )
    
    # Store symbols configuration in app state
    app.state.symbols = load_symbols_config()
    
    @app.get("/")
    async def root():
        """Root endpoint with API information"""
        return {
            "name": "NUNA MQL5 Integration Hub",
            "version": "2.0.0",
            "description": "MetaTrader 5 Trading Bridge API",
            "endpoints": {
                "health": "/health",
                "system": "/system",
                "symbols": "/symbols",
                "config": "/config",
                "docs": "/docs"
            },
            "timestamp": datetime.utcnow().isoformat()
        }
    
    @app.get("/health")
    async def health_check():
        """Enhanced health check with detailed status"""
        mt5_connected = check_mt5_connection()
        bridge_port = int(os.getenv('BRIDGE_PORT', 5555))
        
        return {
            "status": "healthy" if mt5_connected else "degraded",
            "timestamp": datetime.utcnow().isoformat(),
            "services": {
                "mt5_terminal": {
                    "connected": mt5_connected,
                    "path": os.getenv('MT5_TERMINAL_PATH', '/mt5')
                },
                "bridge_server": {
                    "enabled": True,
                    "port": bridge_port
                },
                "api_server": {
                    "enabled": True,
                    "port": int(os.getenv('API_PORT', 8000))
                }
            },
            "symbols_loaded": len(app.state.symbols)
        }
    
    @app.get("/system")
    async def system_info():
        """Get system information"""
        return {
            "platform": {
                "system": platform.system(),
                "release": platform.release(),
                "version": platform.version(),
                "machine": platform.machine(),
                "processor": platform.processor(),
                "python_version": platform.python_version()
            },
            "environment": {
                "mt5_build": os.getenv('MT5_BUILD', 'unknown'),
                "vps_provider": os.getenv('VPS_PROVIDER', 'unknown'),
                "vps_region": os.getenv('VPS_REGION', 'unknown'),
                "terminal_name": os.getenv('TERMINAL_NAME', 'NUNA')
            },
            "configuration": {
                "bridge_port": int(os.getenv('BRIDGE_PORT', 5555)),
                "api_port": int(os.getenv('API_PORT', 8000)),
                "log_level": os.getenv('LOG_LEVEL', 'INFO')
            },
            "timestamp": datetime.utcnow().isoformat()
        }
    
    @app.get("/symbols")
    async def get_symbols():
        """Get all configured trading symbols"""
        return {
            "count": len(app.state.symbols),
            "symbols": list(app.state.symbols.values()),
            "timestamp": datetime.utcnow().isoformat()
        }
    
    @app.get("/symbols/{symbol}")
    async def get_symbol(symbol: str):
        """Get specific symbol configuration"""
        symbol_upper = symbol.upper()
        if symbol_upper not in app.state.symbols:
            raise HTTPException(status_code=404, detail=f"Symbol {symbol} not found")
        
        return {
            "symbol": symbol_upper,
            "config": app.state.symbols[symbol_upper],
            "timestamp": datetime.utcnow().isoformat()
        }
    
    @app.get("/config")
    async def get_config():
        """Get current configuration (non-sensitive data only)"""
        return {
            "account": {
                "terminal_name": os.getenv('TERMINAL_NAME', 'NUNA'),
                "mql5_profile": os.getenv('MQL5_PROFILE', 'not_set'),
                "ea_name": os.getenv('EA_NAME', 'not_set')
            },
            "network": {
                "bridge_port": int(os.getenv('BRIDGE_PORT', 5555)),
                "api_port": int(os.getenv('API_PORT', 8000))
            },
            "integrations": {
                "replit_project": os.getenv('REPLIT_PROJECT', 'not_set'),
                "github_repo": "A6-9V/NUNA",
                "mql5_repo": os.getenv('MQL5_REPO', 'not_set')
            },
            "symbols_count": len(app.state.symbols),
            "timestamp": datetime.utcnow().isoformat()
        }
    
    @app.exception_handler(Exception)
    async def global_exception_handler(request, exc):
        """Global exception handler for better error responses"""
        logger.error(f"Unhandled exception: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "error": "Internal server error",
                "message": str(exc),
                "timestamp": datetime.utcnow().isoformat()
            }
        )
    
    api_port = int(os.getenv('API_PORT', 8000))
    logger.info(f"Starting API server on port {api_port}")
    uvicorn.run(app, host="0.0.0.0", port=api_port)

if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("Starting NUNA MQL5 Integration Hub Service...")
    logger.info("=" * 60)
    
    # Load configuration
    try:
        symbols = load_symbols_config()
        logger.info(f"✓ Loaded {len(symbols)} trading symbols")
        for symbol, config in list(symbols.items())[:5]:  # Show first 5
            logger.info(f"  - {symbol}: {config.get('description', 'No description')}")
        if len(symbols) > 5:
            logger.info(f"  ... and {len(symbols) - 5} more symbols")
    except Exception as e:
        logger.error(f"✗ Failed to load symbols configuration: {e}")
        symbols = {}
    
    # Check MT5 connection
    mt5_connected = check_mt5_connection()
    if mt5_connected:
        logger.info("✓ MT5 terminal connection available")
    else:
        logger.warning("✗ MT5 terminal connection not available (may be normal in cloud environment)")
    
    # Log configuration summary
    logger.info("")
    logger.info("Configuration Summary:")
    logger.info("=" * 60)
    logger.info(f"  Terminal Name    : {os.getenv('TERMINAL_NAME', 'NUNA')}")
    logger.info(f"  MQL5 Profile     : {os.getenv('MQL5_PROFILE', 'Not set')}")
    logger.info(f"  MT5 Account      : {os.getenv('MT5_ACCOUNT', 'Not set')}")
    logger.info(f"  MT5 Server       : {os.getenv('MT5_SERVER', 'Not set')}")
    logger.info(f"  MT5 Connected    : {mt5_connected}")
    logger.info(f"  Bridge Port      : {os.getenv('BRIDGE_PORT', '5555')}")
    logger.info(f"  API Port         : {os.getenv('API_PORT', '8000')}")
    logger.info(f"  Symbols Count    : {len(symbols)}")
    logger.info(f"  Log Level        : {os.getenv('LOG_LEVEL', 'INFO')}")
    logger.info("=" * 60)
    
    # Start services
    import threading
    
    logger.info("")
    logger.info("Starting services...")
    
    # Start bridge server in background thread
    bridge_thread = threading.Thread(target=start_bridge_server, daemon=True, name="BridgeServer")
    bridge_thread.start()
    logger.info("✓ Bridge server thread started")
    
    # Give bridge server time to initialize
    import time
    time.sleep(1)
    
    # Start API server in main thread
    logger.info("✓ Starting API server...")
    logger.info("")
    logger.info("=" * 60)
    logger.info("NUNA MQL5 Integration Hub is ready!")
    logger.info(f"API Documentation: http://localhost:{os.getenv('API_PORT', '8000')}/docs")
    logger.info(f"Bridge Server: localhost:{os.getenv('BRIDGE_PORT', '5555')}")
    logger.info("=" * 60)
    logger.info("")
    
    start_api_server()
