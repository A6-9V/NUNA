"""
Multi-Team Communication Manager
Integrates WhatsApp, Telegram, Perplexity AI, and GPT teams
"""

import json
import logging
from typing import Dict, List, Optional
from datetime import datetime
from pathlib import Path


class CommunicationManager:
    """
    Manages communication across multiple teams:
    - WhatsApp + Perplexity
    - GPT Team (ChatGPT + GitHub Copilot)
    - Perplexity Research Team
    - Jules (Google AI Agent)
    """
    
    def __init__(self, config_path: str = None):
        self.logger = logging.getLogger(__name__)
        self.config = self._load_config(config_path)
        self.teams = self._initialize_teams()
        
    def _load_config(self, config_path: str) -> Dict:
        """Load communication configuration"""
        if config_path and Path(config_path).exists():
            try:
                with open(config_path, 'r') as f:
                    return json.load(f)
            except Exception as e:
                self.logger.error(f"Failed to load config: {e}")
        
        # Default configuration
        return {
            "communication_teams": {},
            "notification_routing": {
                "urgent": {
                    "channels": ["whatsapp", "telegram"],
                    "delay_seconds": 0
                },
                "important": {
                    "channels": ["telegram", "email"],
                    "delay_seconds": 60
                },
                "info": {
                    "channels": ["email"],
                    "delay_seconds": 300
                }
            }
        }
    
    def _initialize_teams(self) -> Dict:
        """Initialize communication teams"""
        teams = {}
        
        team_configs = self.config.get("communication_teams", {})
        
        # WhatsApp + Perplexity Team
        if "whatsapp_perplexity_team" in team_configs:
            teams["whatsapp_perplexity"] = WhatsAppPerplexityTeam(
                team_configs["whatsapp_perplexity_team"]
            )
        
        # GPT Team
        if "gpt_team" in team_configs:
            teams["gpt"] = GPTTeam(
                team_configs["gpt_team"]
            )
        
        # Perplexity Team
        if "perplexity_team" in team_configs:
            teams["perplexity"] = PerplexityTeam(
                team_configs["perplexity_team"]
            )
        
        # Jules Agent
        if "jules_google_agent" in team_configs:
            teams["jules"] = JulesAgent(
                team_configs["jules_google_agent"]
            )
        
        return teams
    
    def send_notification(self,
                         message: str,
                         priority: str = "info",
                         teams: List[str] = None) -> bool:
        """
        Send notification to specified teams
        
        Args:
            message: Notification message
            priority: Priority level (urgent, important, info)
            teams: List of team names to notify (None = all)
            
        Returns:
            Success status
        """
        routing = self.config.get("notification_routing", {}).get(priority, {})
        channels = routing.get("channels", ["telegram"])
        
        success = True
        
        # Determine which teams to notify
        target_teams = teams if teams else list(self.teams.keys())
        
        for team_name in target_teams:
            team = self.teams.get(team_name)
            if team and team.is_enabled():
                try:
                    team.send_message(message, priority)
                    self.logger.info(f"Sent to {team_name}: {message[:50]}...")
                except Exception as e:
                    self.logger.error(f"Failed to send to {team_name}: {e}")
                    success = False
        
        return success
    
    def send_trade_alert(self,
                        symbol: str,
                        direction: str,
                        entry_price: float,
                        stop_loss: float,
                        take_profit: float,
                        confidence: float) -> bool:
        """
        Send trade alert to all teams
        
        Args:
            symbol: Trading symbol
            direction: BUY or SELL
            entry_price: Entry price
            stop_loss: Stop loss price
            take_profit: Take profit price
            confidence: Signal confidence (0-1)
            
        Returns:
            Success status
        """
        message = (
            f"🔔 Trade Signal: {symbol}\n"
            f"Direction: {direction}\n"
            f"Entry: {entry_price:.5f}\n"
            f"SL: {stop_loss:.5f}\n"
            f"TP: {take_profit:.5f}\n"
            f"Confidence: {confidence*100:.1f}%\n"
            f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
        
        return self.send_notification(message, priority="urgent")
    
    def send_position_update(self,
                           symbol: str,
                           action: str,
                           price: float,
                           profit: float) -> bool:
        """
        Send position update notification
        
        Args:
            symbol: Trading symbol
            action: Action taken (OPEN, CLOSE, MODIFY)
            price: Current price
            profit: Profit/loss amount
            
        Returns:
            Success status
        """
        profit_emoji = "✅" if profit >= 0 else "❌"
        
        message = (
            f"{profit_emoji} Position {action}: {symbol}\n"
            f"Price: {price:.5f}\n"
            f"P/L: ${profit:.2f}\n"
            f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
        
        priority = "urgent" if action == "CLOSE" and abs(profit) > 100 else "important"
        
        return self.send_notification(message, priority=priority)
    
    def send_daily_report(self, report: Dict) -> bool:
        """
        Send daily trading report
        
        Args:
            report: Report data dictionary
            
        Returns:
            Success status
        """
        message = (
            f"📊 Daily Trading Report\n"
            f"Date: {datetime.now().strftime('%Y-%m-%d')}\n"
            f"Trades: {report.get('total_trades', 0)}\n"
            f"Wins: {report.get('wins', 0)}\n"
            f"Losses: {report.get('losses', 0)}\n"
            f"Win Rate: {report.get('win_rate', 0):.1f}%\n"
            f"Net P/L: ${report.get('net_profit', 0):.2f}\n"
            f"Balance: ${report.get('balance', 0):.2f}"
        )
        
        return self.send_notification(message, priority="important")
    
    def send_system_alert(self,
                         alert_type: str,
                         message: str,
                         severity: str = "warning") -> bool:
        """
        Send system alert
        
        Args:
            alert_type: Type of alert (ERROR, WARNING, INFO)
            message: Alert message
            severity: Severity level
            
        Returns:
            Success status
        """
        emoji = {
            "error": "🔴",
            "warning": "⚠️",
            "info": "ℹ️"
        }.get(severity.lower(), "ℹ️")
        
        full_message = (
            f"{emoji} System Alert: {alert_type}\n"
            f"{message}\n"
            f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
        
        priority = "urgent" if severity == "error" else "important"
        
        return self.send_notification(full_message, priority=priority)
    
    def request_research(self,
                        topic: str,
                        urgency: str = "normal") -> Optional[str]:
        """
        Request market research from Perplexity team
        
        Args:
            topic: Research topic
            urgency: Request urgency (urgent, normal)
            
        Returns:
            Research result or None
        """
        perplexity_team = self.teams.get("perplexity")
        if perplexity_team:
            try:
                return perplexity_team.research(topic, urgency)
            except Exception as e:
                self.logger.error(f"Research request failed: {e}")
        
        return None
    
    def request_analysis(self,
                        data: Dict,
                        analysis_type: str = "strategy") -> Optional[Dict]:
        """
        Request analysis from GPT team
        
        Args:
            data: Data to analyze
            analysis_type: Type of analysis
            
        Returns:
            Analysis result or None
        """
        gpt_team = self.teams.get("gpt")
        if gpt_team:
            try:
                return gpt_team.analyze(data, analysis_type)
            except Exception as e:
                self.logger.error(f"Analysis request failed: {e}")
        
        return None
    
    def coordinate_decision(self,
                          decision_data: Dict) -> Optional[Dict]:
        """
        Coordinate decision making with Jules agent
        
        Args:
            decision_data: Data for decision making
            
        Returns:
            Decision result or None
        """
        jules = self.teams.get("jules")
        if jules:
            try:
                return jules.coordinate(decision_data)
            except Exception as e:
                self.logger.error(f"Coordination request failed: {e}")
        
        return None


class WhatsAppPerplexityTeam:
    """WhatsApp + Perplexity research team"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.enabled = config.get("enabled", True)
    
    def is_enabled(self) -> bool:
        return self.enabled
    
    def send_message(self, message: str, priority: str = "info") -> bool:
        """Send message via WhatsApp"""
        self.logger.info(f"[WhatsApp] {message[:50]}...")
        # TODO: Implement Twilio WhatsApp integration
        # For now, log the message
        self.logger.debug(f"[WhatsApp] Full message: {message}")
        # Return False until actual implementation is complete
        return False


class GPTTeam:
    """GPT analysis team (ChatGPT + GitHub Copilot)"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.enabled = config.get("enabled", True)
    
    def is_enabled(self) -> bool:
        return self.enabled
    
    def send_message(self, message: str, priority: str = "info") -> bool:
        """Send message to GPT team"""
        self.logger.info(f"[GPT Team] {message[:50]}...")
        return True
    
    def analyze(self, data: Dict, analysis_type: str) -> Optional[Dict]:
        """Perform analysis using GPT"""
        self.logger.info(f"[GPT] Analyzing {analysis_type}")
        # TODO: Implement OpenAI API integration
        # Return placeholder response structure
        return {
            "status": "not_implemented",
            "analysis_type": analysis_type,
            "message": "OpenAI API integration pending",
            "data": data
        }


class PerplexityTeam:
    """Perplexity AI research team"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.enabled = config.get("enabled", True)
    
    def is_enabled(self) -> bool:
        return self.enabled
    
    def send_message(self, message: str, priority: str = "info") -> bool:
        """Send message to Perplexity team"""
        self.logger.info(f"[Perplexity] {message[:50]}...")
        return True
    
    def research(self, topic: str, urgency: str) -> Optional[str]:
        """Conduct market research"""
        self.logger.info(f"[Perplexity] Researching: {topic}")
        # TODO: Implement Perplexity API integration
        # Return placeholder response
        return f"Research pending for topic: {topic} (urgency: {urgency})"


class JulesAgent:
    """Jules - Google AI agent for coordination"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.enabled = config.get("enabled", True)
    
    def is_enabled(self) -> bool:
        return self.enabled
    
    def send_message(self, message: str, priority: str = "info") -> bool:
        """Send message to Jules"""
        self.logger.info(f"[Jules] {message[:50]}...")
        return True
    
    def coordinate(self, decision_data: Dict) -> Optional[Dict]:
        """Coordinate decision making"""
        self.logger.info(f"[Jules] Coordinating decision")
        # TODO: Implement Google AI integration
        # Return placeholder decision structure
        return {
            "status": "not_implemented",
            "coordinator": "Jules",
            "message": "Google AI integration pending",
            "decision_data": decision_data
        }
