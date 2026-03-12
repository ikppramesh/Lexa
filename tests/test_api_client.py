"""Tests for openrouter_client.py — API calls, timeouts, error handling."""

import sys
import os
import time
from unittest.mock import MagicMock, patch
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

import pytest
from openrouter_client import OpenRouterClient, APIError


BASE_CONFIG = {
    "api_key": "test-key",
    "base_url": "https://openrouter.ai/api/v1",
    "model": "openai/gpt-4o-mini",
    "timeout": 5,
    "fallback_models": ["anthropic/claude-haiku-4-5"],
}


def _make_client(config=None):
    return OpenRouterClient(config or BASE_CONFIG)


def _mock_response(content: str, status_code: int = 200):
    mock_resp = MagicMock()
    mock_resp.status_code = status_code
    mock_resp.json.return_value = {
        "choices": [{"message": {"role": "assistant", "content": content}}]
    }
    mock_resp.text = ""
    return mock_resp


class TestSendRequest:
    @patch("openrouter_client.requests.post")
    def test_successful_response(self, mock_post):
        mock_post.return_value = _mock_response("Corrected text.")
        client = _make_client()
        result = client.send_request([{"role": "user", "content": "test"}])
        assert result == "Corrected text."

    @patch("openrouter_client.requests.post")
    def test_strips_whitespace_from_response(self, mock_post):
        mock_post.return_value = _mock_response("  Hello world.  ")
        client = _make_client()
        result = client.send_request([{"role": "user", "content": "test"}])
        assert result == "Hello world."

    @patch("openrouter_client.requests.post")
    def test_401_raises_api_error(self, mock_post):
        mock_post.return_value = _mock_response("", status_code=401)
        client = _make_client()
        with pytest.raises(APIError, match="invalid"):
            client.send_request([{"role": "user", "content": "test"}])

    @patch("openrouter_client.requests.post")
    def test_429_raises_rate_limit_error(self, mock_post):
        mock_post.return_value = _mock_response("", status_code=429)
        client = _make_client()
        with pytest.raises(APIError, match="Rate limit"):
            client.send_request([{"role": "user", "content": "test"}])

    @patch("openrouter_client.requests.post")
    def test_500_raises_api_error(self, mock_post):
        mock_post.return_value = _mock_response("", status_code=500)
        client = _make_client()
        with pytest.raises(APIError):
            client.send_request([{"role": "user", "content": "test"}])

    @patch("openrouter_client.requests.post")
    def test_connection_error_raises_api_error(self, mock_post):
        import requests as req_lib
        mock_post.side_effect = req_lib.exceptions.ConnectionError()
        client = _make_client()
        with pytest.raises(APIError, match="No internet"):
            client.send_request([{"role": "user", "content": "test"}])

    @patch("openrouter_client.requests.post")
    def test_timeout_error_raises_api_error(self, mock_post):
        import requests as req_lib
        mock_post.side_effect = req_lib.exceptions.Timeout()
        client = _make_client()
        with pytest.raises(APIError, match="timed out"):
            client.send_request([{"role": "user", "content": "test"}])

    @patch("openrouter_client.requests.post")
    def test_malformed_response_raises_api_error(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {"unexpected": "data"}
        mock_post.return_value = mock_resp
        client = _make_client()
        with pytest.raises(APIError, match="Unexpected"):
            client.send_request([{"role": "user", "content": "test"}])

    @patch("openrouter_client.requests.post")
    def test_deadline_exceeded_raises_api_error(self, mock_post):
        client = _make_client({**BASE_CONFIG, "timeout": 5})
        # Simulate exhausted time budget by patching monotonic
        with patch("openrouter_client.time.monotonic", return_value=0):
            # deadline = 0 + 5 = 5; second call to monotonic returns value > 5
            pass
        # Direct test: manually set deadline in past
        with pytest.raises(APIError, match="timed out"):
            client._post("openai/gpt-4o-mini", [], 100, 0.3, time.monotonic() - 1)
