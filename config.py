"""Configuration management — loads from env vars with sensible defaults.

Search order for .env:
  1. ~/Library/Application Support/Lexa/.env   (macOS .app install)
  2. ~/.config/lexa/.env                        (Linux package install)
  3. <script directory>/.env                    (local dev)
"""

import os
import platform
import sys
from pathlib import Path

try:
    from dotenv import load_dotenv

    _candidates = [
        Path.home() / "Library" / "Application Support" / "Lexa" / ".env",
        Path.home() / ".config" / "lexa" / ".env",
        Path(__file__).parent / ".env",
    ]
    for _env_path in _candidates:
        if _env_path.exists():
            load_dotenv(_env_path)
            break
except ImportError:
    pass  # rely on shell env


def _get_int(key: str, default: int, max_val: int = None) -> int:
    try:
        val = int(os.environ.get(key, default))
        if max_val is not None:
            val = min(val, max_val)
        return val
    except (ValueError, TypeError):
        return default


def load_config() -> dict:
    return {
        "api_key": os.environ.get("OPENROUTER_API_KEY", ""),
        "model": os.environ.get("CORRECTOR_MODEL", "openai/gpt-4o-mini"),
        "timeout": _get_int("CORRECTOR_TIMEOUT", 30),
        "max_chars": _get_int("CORRECTOR_MAX_CHARS", 2000, max_val=5000),
        "quiet": os.environ.get("CORRECTOR_QUIET", "0") == "1",
        "base_url": "https://openrouter.ai/api/v1",
        "fallback_models": [
            "anthropic/claude-haiku-4-5",
            "mistralai/mistral-7b-instruct",
        ],
    }


def validate_api_key(config: dict) -> None:
    """Exit with a clear message if API key is missing."""
    if not config.get("api_key"):
        print(
            "ERROR: OPENROUTER_API_KEY is not set.\n"
            "Open Lexa from Applications to configure your API key.",
            file=sys.stderr,
        )
        sys.exit(1)
