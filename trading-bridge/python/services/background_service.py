"""
Background Trading Service
Main service that runs trading system in background
"""
import time
import threading
import logging
from pathlib import Path
from datetime import datetime
import socket

# Add parent directories to path
import sys
from pathlib import Path

# Get the trading-bridge/python directory
current_dir = Path(__file__).parent.parent
trading_bridge_dir = current_dir.parent
sys.path.insert(0, str(current_dir))
sys.path.insert(0, str(trading_bridge_dir))

try:
    from bridge.mql5_bridge import MQL5Bridge
    from brokers.broker_factory import BrokerFactory
    from trader.multi_symbol_trader import MultiSymbolTrader
except ImportError as e:
    # Log error but don't crash - allow service to start with minimal functionality
    import logging
    logging.basicConfig(level=logging.ERROR)
    logger = logging.getLogger(__name__)
    logger.error(f"Import error: {e}")
    logger.error(f"Python path: {sys.path}")
    # Set to None to allow graceful degradation
    MQL5Bridge = None
    BrokerFactory = None
    MultiSymbolTrader = None

# Setup logging
log_dir = Path(__file__).parent.parent.parent.parent / "logs"
log_dir.mkdir(parents=True, exist_ok=True)
log_file = log_dir / f"trading_service_{datetime.now().strftime('%Y%m%d')}.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

def _safe_telegram_notify(message: str, *, tag: str) -> None:
    """
    Best-effort Telegram notification (never raises).
    """
    try:
        from notifications.telegram_notifier import TelegramNotifier
        notifier = TelegramNotifier()
        if notifier.is_enabled():
            notifier.send(message, tag=tag)
    except Exception:
        return


class BackgroundTradingService:
    """Main background trading service"""
    
    def __init__(self, bridge_port: int = 5500):
        """
        Initialize background trading service
        
        Args:
            bridge_port: Port for MQL5 bridge
        """
        self.bridge_port = bridge_port
        self.bridge = None
        self.brokers = {}
        self.trader = None
        self.running = False
        self.bridge_thread = None
        
        # Health check
        self.last_health_check = None
        self.health_check_interval = 60  # seconds
        
        # Check if modules are available
        self.modules_available = MQL5Bridge is not None
    
    def start(self):
        """Start the trading service"""
        try:
            logger.info("Starting Background Trading Service...")
            _safe_telegram_notify(
                f"Service starting. Host={socket.gethostname()} Port={self.bridge_port}",
                tag="START",
            )
            
            if not self.modules_available:
                logger.warning("Trading modules not fully available - running in minimal mode")
                logger.warning("Service will run but trading functionality may be limited")
                self.running = True
                _safe_telegram_notify(
                    "Modules not available (minimal mode). Check dependencies/imports.",
                    tag="WARNING",
                )
                self._service_loop_minimal()
                return
            
            # Initialize bridge
            self.bridge = MQL5Bridge(port=self.bridge_port)
            
            # Start bridge in separate thread
            self.bridge_thread = threading.Thread(target=self._run_bridge, daemon=True)
            self.bridge_thread.start()
            
            # Wait for bridge to start
            time.sleep(2)
            
            # Initialize brokers
            logger.info("Loading brokers...")
            self.brokers = BrokerFactory.create_all_brokers()
            logger.info(f"Loaded {len(self.brokers)} broker(s)")
            
            # Initialize multi-symbol trader
            self.trader = MultiSymbolTrader(bridge=self.bridge, broker_manager=self.brokers)
            logger.info("Multi-symbol trader initialized")
            
            # Start main loop
            self.running = True
            logger.info("Background Trading Service started")
            _safe_telegram_notify("Service started successfully.", tag="OK")
            
            # Main service loop
            self._service_loop()
            
        except Exception as e:
            logger.error(f"Failed to start service: {e}")
            import traceback
            logger.error(traceback.format_exc())
            _safe_telegram_notify(f"Service failed to start: {e}", tag="ERROR")
            # Don't raise - allow service to continue in minimal mode
            self.running = True
            self._service_loop_minimal()
    
    def _run_bridge(self):
        """Run bridge in separate thread"""
        try:
            self.bridge.start()
        except Exception as e:
            logger.error(f"Bridge error: {e}")
    
    def _service_loop(self):
        """Main service loop"""
        while self.running:
            try:
                # Health check
                self._health_check()
                
                # Monitor positions
                if self.trader:
                    self.trader.monitor_positions()
                
                # Check bridge status
                if self.bridge:
                    status = self.bridge.get_status()
                    if status['connection_status'] == 'disconnected':
                        logger.warning("Bridge disconnected, attempting to reconnect...")
                        # Bridge will auto-reconnect on next request
                
                # Sleep before next iteration
                time.sleep(5)
                
            except KeyboardInterrupt:
                logger.info("Service interrupted by user")
                self.stop()
                break
            except Exception as e:
                logger.error(f"Service loop error: {e}")
                time.sleep(10)
    
    def _service_loop_minimal(self):
        """Minimal service loop when modules not available"""
        while self.running:
            try:
                logger.info("Service running in minimal mode - waiting for modules")
                time.sleep(60)  # Check every minute
            except KeyboardInterrupt:
                logger.info("Service interrupted by user")
                self.stop()
                break
            except Exception as e:
                logger.error(f"Service loop error: {e}")
                time.sleep(10)
    
    def _health_check(self):
        """Perform health check"""
        current_time = time.time()
        
        if (self.last_health_check is None or 
            current_time - self.last_health_check >= self.health_check_interval):
            
            # Check bridge
            if self.bridge:
                status = self.bridge.get_status()
                logger.debug(f"Bridge status: {status['connection_status']}")
            
            # Check brokers
            for broker_name, broker in self.brokers.items():
                try:
                    account_info = broker.get_account_info()
                    logger.debug(f"{broker_name} account balance: {account_info.balance}")
                except Exception as e:
                    logger.warning(f"{broker_name} health check failed: {e}")
            
            self.last_health_check = current_time
    
    def stop(self):
        """Stop the trading service"""
        logger.info("Stopping Background Trading Service...")
        self.running = False
        
        if self.bridge:
            self.bridge.stop()
        
        logger.info("Background Trading Service stopped")
        _safe_telegram_notify("Service stopped.", tag="STOP")
    
    def get_status(self) -> dict:
        """Get service status"""
        status = {
            'running': self.running,
            'bridge_status': None,
            'brokers': list(self.brokers.keys()),
            'symbols': []
        }
        
        if self.bridge:
            status['bridge_status'] = self.bridge.get_status()
        
        if self.trader:
            status['symbols'] = [s['symbol'] for s in self.trader.get_all_symbols()]
        
        return status


def main():
    """Main entry point"""
    service = BackgroundTradingService()
    try:
        service.start()
    except KeyboardInterrupt:
        logger.info("Service stopped by user")
        service.stop()
    except Exception as e:
        logger.error(f"Service error: {e}")
        service.stop()
        raise


if __name__ == "__main__":
    main()

