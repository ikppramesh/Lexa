"""Tests for assistant.py — mode routing, input validation, truncation."""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from assistant import validate_input, truncate_input


class TestValidateInput:
    def test_strips_whitespace(self):
        assert validate_input("  hello  ") == "hello"

    def test_empty_string_returns_empty(self):
        assert validate_input("") == ""

    def test_none_returns_empty(self):
        assert validate_input(None) == ""

    def test_only_whitespace_returns_empty(self):
        assert validate_input("   \n\t  ") == ""

    def test_preserves_internal_content(self):
        text = "Hello, world!"
        assert validate_input(text) == text


class TestTruncateInput:
    def test_short_text_unchanged(self):
        text = "Short text"
        result, was_truncated = truncate_input(text, 2000)
        assert result == text
        assert was_truncated is False

    def test_exact_limit_unchanged(self):
        text = "x" * 2000
        result, was_truncated = truncate_input(text, 2000)
        assert result == text
        assert was_truncated is False

    def test_over_limit_truncated(self):
        text = "x" * 2500
        result, was_truncated = truncate_input(text, 2000)
        assert len(result) == 2000
        assert was_truncated is True

    def test_truncation_respects_max_chars(self):
        text = "abcde"
        result, was_truncated = truncate_input(text, 3)
        assert result == "abc"
        assert was_truncated is True
