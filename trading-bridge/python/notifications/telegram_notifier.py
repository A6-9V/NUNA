"""
Telegram notifications for Trading Bridge.

Secrets are retrieved via CredentialManager (Windows Credential Manager first, then env vars).

Credential keys:
  - TELEGRAM_BOT_TOKEN
  - TELEGRAM_CHAT_ID

Env var fallback names (because CredentialManager prefix is TradingBridge_):
  - TRADINGBRIDGE_TELEGRAM_BOT_TOKEN
  - TRADINGBRIDGE_TELEGRAM_CHAT_ID
"""

from __future__ import annotations

import json
import platform
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Optional

try:
    from security.credential_manager import get_credential
except Exception:  # pragma: no cover
    get_credential = None  # type: ignore


@dataclass(frozen=True)
class TelegramConfig:
    bot_token: str
    chat_id: str


class TelegramNotifier:
    def __init__(self, config: Optional[TelegramConfig] = None, timeout_seconds: int = 10):
        self.timeout_seconds = timeout_seconds
        self._config = config or self._load_config()

    @staticmethod
    def _load_config() -> Optional[TelegramConfig]:
        if get_credential is None:
            return None

        token = get_credential("TELEGRAM_BOT_TOKEN")
        chat_id = get_credential("TELEGRAM_CHAT_ID")
        if not token or not chat_id:
            return None
        return TelegramConfig(bot_token=token.strip(), chat_id=chat_id.strip())

    def is_enabled(self) -> bool:
        return self._config is not None

    def send(self, message: str, *, tag: str = "TRADING") -> bool:
        """
        Send a Telegram message. Returns True on success, False otherwise.
        Never raises (best-effort).
        """
        if not self._config:
            return False

        try:
            host = platform.node() or "unknown-host"
            full_message = f"[{tag}] {host}\n{message}"

            url = f"https://api.telegram.org/bot{self._config.bot_token}/sendMessage"
            payload = {
                "chat_id": self._config.chat_id,
                "text": full_message,
                "disable_web_page_preview": True,
            }

            data = urllib.parse.urlencode(payload).encode("utf-8")
            req = urllib.request.Request(url, data=data, method="POST")
            with urllib.request.urlopen(req, timeout=self.timeout_seconds) as resp:
                body = resp.read().decode("utf-8", errors="replace")
                parsed = json.loads(body) if body else {}
                return bool(parsed.get("ok", False))
        except Exception:
            return False

