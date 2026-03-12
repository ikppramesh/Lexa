"""Popup window for displaying AI explanations and corrections.

On macOS the popup uses osascript (AppleScript) as the primary renderer
because tkinter's Tcl/Tk crashes when launched from an Automator service
(no GUI session / display context). tkinter is used as a fallback on Linux
or when running directly from the terminal.
"""

import platform
import subprocess
import sys

MAX_DISPLAY_CHARS = 500


# ── Public API ────────────────────────────────────────────────────────────────

def show_loader():
    """Show a non-blocking 'processing' dialog. Returns Popen handle; pass to hide_loader() when done."""
    if platform.system() == "Darwin":
        return _osascript_loader_show()
    return None


def hide_loader(proc) -> None:
    """Kill the loader dialog spawned by show_loader()."""
    if proc and proc.poll() is None:
        proc.kill()


def show_explanation(original: str, explanation: str) -> None:
    """Show explanation popup: original text + plain-English explanation."""
    if platform.system() == "Darwin":
        _osascript_explanation(original, explanation)
    else:
        _tkinter_popup(
            header="💡 AI Text Explanation",
            section1_label="Selected Text:",
            section1_text=original,
            section2_label="Explanation:",
            section2_text=explanation,
            copy_text=explanation,
        )


def show_correction(original: str, corrected: str) -> None:
    """Show correction comparison popup (original vs corrected)."""
    if platform.system() == "Darwin":
        _osascript_correction(original, corrected)
    else:
        _tkinter_popup(
            header="✍️ AI Correction",
            section1_label="Original Text:",
            section1_text=original,
            section2_label="Corrected Text:",
            section2_text=corrected,
            copy_text=corrected,
        )


def show_error(title: str, message: str, on_retry=None) -> None:
    """Show an error popup with optional retry affordance."""
    if platform.system() == "Darwin":
        _osascript_error(title, message)
    else:
        _tkinter_error(title, message, on_retry)


# ── macOS osascript implementation ────────────────────────────────────────────

def _esc(text: str) -> str:
    """Escape text for safe embedding in an AppleScript string literal."""
    return text.replace("\\", "\\\\").replace('"', '\\"')


def _osascript_explanation(original: str, explanation: str) -> None:
    _, display_explanation, full_explanation = _prepare_text(explanation)
    truncation_note = "\n\n(Explanation truncated — full text copied to clipboard)" if len(explanation) > MAX_DISPLAY_CHARS else ""

    script = f"""
set orig to "{_esc(original[:300])}"
set expl to "{_esc(display_explanation)}{_esc(truncation_note)}"

set dialogText to "Selected Text:" & return & orig & return & return & "Explanation:" & return & expl

set btn to button returned of (display dialog dialogText ¬
    with title "💡 AI Text Explanation" ¬
    buttons {{"Copy Explanation", "Close"}} ¬
    default button "Copy Explanation" ¬
    with icon note)

if btn is "Copy Explanation" then
    set the clipboard to "{_esc(full_explanation)}"
end if
"""
    _run_osascript(script)


def _osascript_correction(original: str, corrected: str) -> None:
    script = f"""
set orig to "{_esc(original[:300])}"
set corr to "{_esc(corrected)}"

set dialogText to "Original:" & return & orig & return & return & "Corrected:" & return & corr

set btn to button returned of (display dialog dialogText ¬
    with title "✍️ AI Correction" ¬
    buttons {{"Copy Corrected", "Close"}} ¬
    default button "Copy Corrected" ¬
    with icon note)

if btn is "Copy Corrected" then
    set the clipboard to "{_esc(corrected)}"
end if
"""
    _run_osascript(script)


def _osascript_error(title: str, message: str) -> None:
    script = f"""
display dialog "{_esc(message)}" ¬
    with title "❌ {_esc(title)}" ¬
    buttons {{"OK"}} ¬
    default button "OK" ¬
    with icon caution
"""
    _run_osascript(script)


def _osascript_loader_show():
    """Show a non-interactive 'processing' notification banner. Returns None (no proc to track)."""
    try:
        subprocess.run(
            ["osascript", "-e",
             'display notification "AI is analyzing your text, please wait..." '
             'with title "Lexa — Working" sound name "Pop"'],
            capture_output=True, timeout=3,
        )
    except Exception:
        pass
    return None  # notification auto-dismisses; nothing to kill later


def _run_osascript(script: str) -> None:
    try:
        subprocess.run(["osascript", "-e", script], check=False)
    except FileNotFoundError:
        print(f"osascript not found", file=sys.stderr)


# ── tkinter implementation (Linux / terminal fallback) ────────────────────────

def _tkinter_popup(
    header: str,
    section1_label: str,
    section1_text: str,
    section2_label: str,
    section2_text: str,
    copy_text: str,
) -> None:
    import tkinter as tk
    from tkinter import font as tkfont

    root = tk.Tk()
    root.title(header)
    root.resizable(False, False)

    BG = "#f9f9f9"
    WIDTH = 520

    root.configure(bg=BG)
    outer = tk.Frame(root, bg=BG, padx=20, pady=16)
    outer.pack(fill=tk.BOTH, expand=True)

    tk.Label(outer, text=header, font=tkfont.Font(family="Helvetica", size=14, weight="bold"),
             bg=BG, anchor="w").pack(fill=tk.X, pady=(0, 12))

    _tk_section(outer, section1_label, section1_text, WIDTH, BG)
    tk.Frame(outer, height=8, bg=BG).pack()

    is_truncated, display_text, full_text = _prepare_text(section2_text)
    _tk_section(outer, section2_label, display_text, WIDTH, BG)
    if is_truncated:
        tk.Label(outer, text="… (truncated — copy for full text)",
                 font=("Helvetica", 9), fg="#888888", bg=BG).pack(anchor="w", pady=(2, 0))

    btn_frame = tk.Frame(outer, bg=BG)
    btn_frame.pack(pady=(14, 0), anchor="e")

    def do_copy():
        root.clipboard_clear()
        root.clipboard_append(full_text)
        root.update()

    tk.Button(btn_frame, text="📋 Copy", command=do_copy,
              relief=tk.FLAT, bg="#0066cc", fg="white", padx=12, pady=5,
              cursor="hand2").pack(side=tk.LEFT, padx=(0, 8))
    tk.Button(btn_frame, text="✖ Close", command=root.destroy,
              relief=tk.FLAT, bg="#e0e0e0", padx=12, pady=5,
              cursor="hand2").pack(side=tk.LEFT)

    root.bind("<Escape>", lambda _: root.destroy())
    _tk_center(root)
    root.mainloop()


def _tkinter_error(title: str, message: str, on_retry=None) -> None:
    import tkinter as tk

    root = tk.Tk()
    root.title(title)
    root.resizable(False, False)

    frame = tk.Frame(root, padx=20, pady=20, bg="#fff8f8")
    frame.pack(fill=tk.BOTH, expand=True)
    tk.Label(frame, text=f"❌  {title}", font=("Helvetica", 13, "bold"),
             fg="#cc0000", bg="#fff8f8").pack(anchor="w", pady=(0, 10))
    tk.Label(frame, text=message, wraplength=380, justify=tk.LEFT, bg="#fff8f8").pack(anchor="w")

    btn_frame = tk.Frame(frame, bg="#fff8f8")
    btn_frame.pack(pady=(16, 0), anchor="e")
    if on_retry:
        tk.Button(btn_frame, text="🔄 Retry",
                  command=lambda: [root.destroy(), on_retry()]).pack(side=tk.LEFT, padx=(0, 8))
    tk.Button(btn_frame, text="✖ Close", command=root.destroy).pack(side=tk.LEFT)

    root.bind("<Escape>", lambda _: root.destroy())
    _tk_center(root)
    root.mainloop()


def _tk_section(parent, label: str, text: str, width: int, bg: str) -> None:
    import tkinter as tk
    tk.Label(parent, text=label, font=("Helvetica", 10, "bold"),
             bg=bg, anchor="w").pack(fill=tk.X, pady=(0, 4))
    container = tk.Frame(parent, bg="#dddddd", bd=1, relief=tk.FLAT)
    container.pack(fill=tk.X)
    tk.Label(container, text=text, wraplength=width - 24, justify=tk.LEFT,
             bg="#ffffff", font=("Helvetica", 11), padx=10, pady=8,
             anchor="nw").pack(fill=tk.X)


def _tk_center(root) -> None:
    import tkinter as tk
    root.update_idletasks()
    w, h = root.winfo_width(), root.winfo_height()
    sw, sh = root.winfo_screenwidth(), root.winfo_screenheight()
    root.geometry(f"+{(sw - w) // 2}+{(sh - h) // 2}")


# ── Shared helpers ────────────────────────────────────────────────────────────

def _prepare_text(text: str) -> tuple:
    """Returns (is_truncated, display_text, full_text)."""
    if len(text) <= MAX_DISPLAY_CHARS:
        return False, text, text
    return True, text[:MAX_DISPLAY_CHARS], text
