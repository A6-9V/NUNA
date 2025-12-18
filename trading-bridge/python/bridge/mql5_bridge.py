"""
Python-MQL5 Bridge
ZeroMQ-based communication bridge between Python trading engine and MQL5 EA
"""
import zmq
import json
import time
import threading
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from pathlib import Path

from .signal_manager import SignalManager, TradeSignal


# Setup logging
log_dir = Path(__file__).parent.parent.parent.parent / "logs"
log_dir.mkdir(parents=True, exist_ok=True)
log_file = log_dir / f"mql5_bridge_{datetime.now().strftime('%Y%m%d')}.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)


class MQL5Bridge:
    """Bridge between Python trading engine and MQL5 EA"""
    
    def __init__(self, port: int = 5500, host: str = "127.0.0.1"):
        """
        Initialize MQL5 Bridge
        
        Args:
            port: ZeroMQ port number
            host: Host address (default: localhost)
        """
        self.port = port
        self.host = host
        self.context = None
        self.socket = None
        self.running = False
        self.signal_manager = SignalManager()
        self.connection_status = "disconnected"
        self.last_heartbeat = None
        self.heartbeat_timeout = 30  # seconds
        
        # Statistics
        self.stats = {
            'signals_sent': 0,
            'signals_received': 0,
            'errors': 0,
            'reconnections': 0
        }
    
    def start(self):
        """Start the bridge server"""
        try:
            self.context = zmq.Context()
            self.socket = self.context.socket(zmq.REP)
            bind_address = f"tcp://{self.host}:{self.port}"
            self.socket.bind(bind_address)
            self.socket.setsockopt(zmq.RCVTIMEO, 5000)  # 5 second timeout
            
            self.running = True
            self.connection_status = "listening"
            logger.info(f"MQL5 Bridge started on {bind_address}")
            
            # Start heartbeat monitor
            heartbeat_thread = threading.Thread(target=self._monitor_heartbeat, daemon=True)
            heartbeat_thread.start()
            
            # Main loop
            self._run()
            
        except Exception as e:
            logger.error(f"Failed to start bridge: {e}")
            self.connection_status = "error"
            raise
    
    def _run(self):
        """Main bridge loop"""
        while self.running:
            try:
                # Wait for request from MQL5 EA
                try:
                    message = self.socket.recv_string(zmq.NOBLOCK)
                except zmq.Again:
                    time.sleep(0.1)
                    continue
                
                # Parse request
                try:
                    request = json.loads(message)
                except json.JSONDecodeError as e:
                    logger.error(f"Invalid JSON received: {e}")
                    response = {'status': 'ERROR', 'message': 'Invalid JSON'}
                    self.socket.send_string(json.dumps(response))
                    continue
                
                # Process request
                response = self._process_request(request)
                
                # Send response
                self.socket.send_string(json.dumps(response))
                
            except Exception as e:
                logger.error(f"Bridge error: {e}")
                self.stats['errors'] += 1
                if self.running:
                    response = {'status': 'ERROR', 'message': str(e)}
                    try:
                        self.socket.send_string(json.dumps(response))
                    except:
                        pass
                time.sleep(1)
    
    def _process_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process request from MQL5 EA
        
        Args:
            request: Request dictionary
            
        Returns:
            Response dictionary
        """
        action = request.get('action', '').upper()
        
        if action == 'GET_SIGNALS':
            # Return pending trade signals
            count = request.get('count', None)
            signals = self.signal_manager.get_signals(count)
            signal_dicts = [s.to_dict() for s in signals]
            self.stats['signals_sent'] += len(signals)
            logger.info(f"Sending {len(signals)} signals to MQL5")
            return {
                'status': 'OK',
                'signals': signal_dicts,
                'queue_size': self.signal_manager.get_queue_size()
            }
        
        elif action == 'SEND_STATUS':
            # Receive status from MQL5
            status = request.get('status', '')
            message = request.get('message', '')
            self.last_heartbeat = datetime.now()
            self.connection_status = "connected"
            logger.debug(f"MQL5 Status: {status} - {message}")
            return {'status': 'OK'}
        
        elif action == 'HEARTBEAT':
            # Heartbeat from MQL5
            self.last_heartbeat = datetime.now()
            self.connection_status = "connected"
            return {
                'status': 'OK',
                'timestamp': datetime.now().isoformat(),
                'queue_size': self.signal_manager.get_queue_size()
            }
        
        elif action == 'GET_BRIDGE_STATUS':
            # Get bridge status
            return {
                'status': 'OK',
                'connection_status': self.connection_status,
                'queue_size': self.signal_manager.get_queue_size(),
                'stats': self.stats,
                'last_heartbeat': self.last_heartbeat.isoformat() if self.last_heartbeat else None
            }
        
        else:
            logger.warning(f"Unknown action: {action}")
            return {'status': 'ERROR', 'message': f'Unknown action: {action}'}
    
    def send_signal(self, signal: TradeSignal) -> tuple[bool, Optional[str]]:
        """
        Send trade signal to MQL5
        
        Args:
            signal: Trade signal to send
            
        Returns:
            (success, error_message)
        """
        success, error = self.signal_manager.add_signal(signal)
        if success:
            logger.info(f"Signal queued: {signal.action} {signal.symbol} @ {signal.broker}")
        else:
            logger.warning(f"Failed to queue signal: {error}")
        return success, error
    
    def _monitor_heartbeat(self):
        """Monitor MQL5 connection heartbeat"""
        while self.running:
            time.sleep(5)
            if self.last_heartbeat:
                elapsed = (datetime.now() - self.last_heartbeat).total_seconds()
                if elapsed > self.heartbeat_timeout:
                    self.connection_status = "disconnected"
                    logger.warning(f"MQL5 connection lost (no heartbeat for {elapsed:.1f}s)")
    
    def stop(self):
        """Stop the bridge"""
        self.running = False
        if self.socket:
            self.socket.close()
        if self.context:
            self.context.term()
        self.connection_status = "stopped"
        logger.info("MQL5 Bridge stopped")
    
    def get_status(self) -> Dict[str, Any]:
        """Get bridge status"""
        return {
            'connection_status': self.connection_status,
            'queue_size': self.signal_manager.get_queue_size(),
            'stats': self.stats.copy(),
            'last_heartbeat': self.last_heartbeat.isoformat() if self.last_heartbeat else None
        }


# Convenience function for standalone usage
def start_bridge(port: int = 5500, host: str = "127.0.0.1"):
    """Start bridge server (for standalone usage)"""
    bridge = MQL5Bridge(port=port, host=host)
    try:
        bridge.start()
    except KeyboardInterrupt:
        logger.info("Stopping bridge...")
        bridge.stop()

if __name__ == "__main__":
    start_bridge()

