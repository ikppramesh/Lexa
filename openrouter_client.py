"""OpenRouter API client with timeout and fallback model support."""

import time
import requests


class APIError(Exception):
    """Raised when the API returns an error or the request fails."""
    pass


class OpenRouterClient:
    def __init__(self, config: dict):
        self.api_key = config["api_key"]
        self.base_url = config["base_url"]
        self.model = config["model"]
        self.timeout = config["timeout"]
        self.fallback_models = config.get("fallback_models", [])

    def _post(self, model: str, messages: list[dict], max_tokens: int, temperature: float, deadline: float) -> str:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise APIError("Request timed out — try again")

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://github.com/lexa/english-corrector",
            "X-Title": "Lexa English Corrector",
        }
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }

        try:
            resp = requests.post(
                f"{self.base_url}/chat/completions",
                json=payload,
                headers=headers,
                timeout=min(remaining, self.timeout),
            )
        except requests.exceptions.ConnectionError:
            raise APIError("No internet connection")
        except requests.exceptions.Timeout:
            raise APIError("Request timed out — try again")

        if resp.status_code == 401:
            raise APIError("API key invalid — check your OPENROUTER_API_KEY")
        if resp.status_code == 429:
            raise APIError("Rate limit exceeded — try again later")
        if resp.status_code >= 400:
            raise APIError(f"API error {resp.status_code}: {resp.text[:200]}")

        data = resp.json()
        try:
            return data["choices"][0]["message"]["content"].strip()
        except (KeyError, IndexError):
            raise APIError("Unexpected API response format")

    def send_request(self, messages: list[dict], max_tokens: int = 500, temperature: float = 0.3) -> str:
        """Send a chat completion request with automatic fallback on failure."""
        deadline = time.monotonic() + self.timeout
        models_to_try = [self.model] + self.fallback_models
        last_error = None

        for model in models_to_try:
            try:
                return self._post(model, messages, max_tokens, temperature, deadline)
            except APIError as e:
                last_error = e
                # Only retry with fallback for transient errors, not auth/rate-limit
                error_msg = str(e)
                if "invalid" in error_msg or "Rate limit" in error_msg:
                    raise
                # Check if we still have time budget for a fallback attempt
                if time.monotonic() >= deadline:
                    break

        raise last_error or APIError("All models failed")
