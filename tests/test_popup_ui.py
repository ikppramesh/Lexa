"""Tests for popup_ui.py — text preparation and truncation logic."""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from popup_ui import _prepare_text, MAX_DISPLAY_CHARS


class TestPrepareText:
    def test_short_text_not_truncated(self):
        text = "Hello world"
        is_truncated, display, full = _prepare_text(text)
        assert is_truncated is False
        assert display == text
        assert full == text

    def test_exact_limit_not_truncated(self):
        text = "x" * MAX_DISPLAY_CHARS
        is_truncated, display, full = _prepare_text(text)
        assert is_truncated is False
        assert len(display) == MAX_DISPLAY_CHARS

    def test_over_limit_is_truncated(self):
        text = "x" * (MAX_DISPLAY_CHARS + 100)
        is_truncated, display, full = _prepare_text(text)
        assert is_truncated is True
        assert len(display) == MAX_DISPLAY_CHARS
        assert full == text  # Full text preserved for copy

    def test_full_text_preserved_after_truncation(self):
        text = "A" * 600 + "UNIQUE_SUFFIX"
        is_truncated, display, full = _prepare_text(text)
        assert is_truncated is True
        assert "UNIQUE_SUFFIX" not in display
        assert "UNIQUE_SUFFIX" in full

    def test_empty_string(self):
        is_truncated, display, full = _prepare_text("")
        assert is_truncated is False
        assert display == ""
        assert full == ""
