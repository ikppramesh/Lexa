"""Tests for prompts.py"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from prompts import get_correct_prompt, get_explain_prompt, CORRECT_SYSTEM, EXPLAIN_SYSTEM


def test_correct_prompt_structure():
    messages = get_correct_prompt("Hello world")
    assert len(messages) == 2
    assert messages[0]["role"] == "system"
    assert messages[1]["role"] == "user"


def test_correct_prompt_includes_text():
    text = "I didn't went to office"
    messages = get_correct_prompt(text)
    assert text in messages[1]["content"]


def test_correct_system_prompt_rules():
    assert "Preserve" in CORRECT_SYSTEM
    assert "Return only the corrected text" in CORRECT_SYSTEM


def test_explain_prompt_structure():
    messages = get_explain_prompt("Some jargon text")
    assert len(messages) == 2
    assert messages[0]["role"] == "system"
    assert messages[1]["role"] == "user"


def test_explain_prompt_includes_text():
    text = "ingress controller misconfigured"
    messages = get_explain_prompt(text)
    assert text in messages[1]["content"]


def test_explain_system_prompt_rules():
    assert "plain" in EXPLAIN_SYSTEM.lower()
    assert "simple" in EXPLAIN_SYSTEM.lower()


def test_prompts_return_list_of_dicts():
    for fn, text in [(get_correct_prompt, "test"), (get_explain_prompt, "test")]:
        result = fn(text)
        assert isinstance(result, list)
        for msg in result:
            assert isinstance(msg, dict)
            assert "role" in msg
            assert "content" in msg
