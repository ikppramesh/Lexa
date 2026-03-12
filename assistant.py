#!/usr/bin/env python3
"""
Lexa — AI English Correction & Explanation Assistant
Main CLI entry point.

Usage:
    python3 assistant.py --correct         # Correct text on clipboard
    python3 assistant.py --explain         # Explain text on clipboard
    echo "some text" | python3 assistant.py --correct   # Pipe input
"""

import argparse
import platform
import subprocess
import sys

from config import load_config, validate_api_key
from notifications import show_notification
from openrouter_client import APIError, OpenRouterClient
from prompts import get_correct_prompt, get_explain_prompt


def read_clipboard() -> str:
    """Read text from system clipboard."""
    system = platform.system()
    try:
        if system == "Darwin":
            result = subprocess.run(["pbpaste"], capture_output=True, text=True, check=True)
            return result.stdout
        elif system == "Linux":
            # Try primary selection first — this holds highlighted text on Linux
            # (works on both X11 and Wayland/XWayland without needing Ctrl+C)
            try:
                result = subprocess.run(
                    ["xclip", "-selection", "primary", "-o"],
                    capture_output=True,
                    text=True,
                    check=True,
                )
                if result.stdout.strip():
                    return result.stdout
            except (subprocess.CalledProcessError, FileNotFoundError):
                pass
            # Fall back to clipboard (Ctrl+C copied text)
            result = subprocess.run(
                ["xclip", "-selection", "clipboard", "-o"],
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    try:
        import pyperclip
        return pyperclip.paste()
    except Exception:
        return ""


def write_clipboard(text: str) -> None:
    """Write text to system clipboard."""
    system = platform.system()
    try:
        if system == "Darwin":
            subprocess.run(["pbcopy"], input=text.encode(), check=True)
            return
        elif system == "Linux":
            subprocess.run(
                ["xclip", "-selection", "clipboard"],
                input=text.encode(),
                check=True,
            )
            return
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    try:
        import pyperclip
        pyperclip.copy(text)
    except Exception as e:
        print(f"WARNING: Could not write to clipboard: {e}", file=sys.stderr)


def get_input_text(use_stdin: bool) -> str:
    """Get text from stdin or clipboard."""
    if use_stdin:
        return sys.stdin.read()
    return read_clipboard()


def validate_input(text: str) -> str:
    """Strip whitespace and return clean text, or empty string."""
    return text.strip() if text else ""


def truncate_input(text: str, max_chars: int) -> tuple[str, bool]:
    """Return (text, was_truncated)."""
    if len(text) <= max_chars:
        return text, False
    return text[:max_chars], True


def _dismiss_loader(loader) -> None:
    """Dismiss the loading dialog if still open."""
    if loader:
        try:
            from popup_ui import hide_loader
            hide_loader(loader)
        except Exception:
            pass


def run_correct(text: str, client: OpenRouterClient, config: dict, loader=None) -> None:
    messages = get_correct_prompt(text)
    corrected = client.send_request(messages, max_tokens=500, temperature=0.3)

    # Dismiss loader before result dialog so they don't overlap
    _dismiss_loader(loader)

    write_clipboard(corrected)
    print(corrected)

    # Show a visible confirmation dialog — notifications are silently blocked
    # by macOS when triggered from Automator services.
    try:
        from popup_ui import show_correction
        show_correction(original=text, corrected=corrected)
    except Exception:
        show_notification("Lexa", "Correction copied to clipboard", config["quiet"])


def run_explain(text: str, client: OpenRouterClient, config: dict, loader=None) -> None:
    quiet = config["quiet"]
    messages = get_explain_prompt(text)
    explanation = client.send_request(messages, max_tokens=300, temperature=0.5)

    # Dismiss loader before result dialog so they don't overlap
    _dismiss_loader(loader)

    show_notification("Lexa", "Explanation ready", quiet)

    try:
        from popup_ui import show_explanation
        show_explanation(original=text, explanation=explanation)
    except Exception as e:
        # Fallback: print to stdout if tkinter not available
        print(f"--- Original ---\n{text}\n\n--- Explanation ---\n{explanation}")
        if not quiet:
            print(f"(Popup unavailable: {e})", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Lexa — AI English Correction & Explanation"
    )
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument("--correct", action="store_true", help="Correct grammar and spelling")
    mode_group.add_argument("--explain", action="store_true", help="Explain text in plain English")
    parser.add_argument("--quiet", action="store_true", help="Suppress system notifications")

    args = parser.parse_args()

    config = load_config()
    if args.quiet:
        config["quiet"] = True

    validate_api_key(config)

    use_stdin = not sys.stdin.isatty()
    raw_text = get_input_text(use_stdin)
    text = validate_input(raw_text)

    if not text:
        msg = "No text selected"
        show_notification("Lexa", msg, config["quiet"])
        print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    text, was_truncated = truncate_input(text, config["max_chars"])
    if was_truncated:
        show_notification("Lexa", f"Text truncated to {config['max_chars']} chars", config["quiet"])

    client = OpenRouterClient(config)

    # Show loading dialog — visible while the API call is in flight
    loader = None
    try:
        from popup_ui import show_loader
        loader = show_loader()
    except Exception:
        pass

    try:
        if args.correct:
            run_correct(text, client, config, loader=loader)
        else:
            run_explain(text, client, config, loader=loader)
    except APIError as e:
        error_msg = str(e)
        _dismiss_loader(loader)
        loader = None
        show_notification("Lexa", error_msg, config["quiet"])
        print(f"ERROR: {error_msg}", file=sys.stderr)

        try:
            from popup_ui import show_error
            if args.explain:
                show_error("Lexa Error", error_msg, on_retry=lambda: main())
        except Exception:
            pass

        sys.exit(1)
    finally:
        _dismiss_loader(loader)  # safety net if anything else raises


if __name__ == "__main__":
    main()
