"""OS-native notification abstraction for macOS and Linux."""

import platform
import subprocess


def show_notification(title: str, message: str, quiet: bool = False) -> None:
    """Display a system notification. Silently fails if unsupported."""
    if quiet:
        return

    system = platform.system()
    try:
        if system == "Darwin":
            script = f'display notification "{message}" with title "{title}"'
            subprocess.run(["osascript", "-e", script], check=False, capture_output=True)
        elif system == "Linux":
            subprocess.run(
                ["notify-send", title, message],
                check=False,
                capture_output=True,
            )
    except FileNotFoundError:
        pass  # Notification tool not available — silently skip
