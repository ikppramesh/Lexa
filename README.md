# Lexa — AI English Correction & Explanation

Lexa is a lightweight, system-level AI writing assistant that works in **any app** — email, Slack, IDE, browser, terminal. Select any text, right-click, and instantly correct your English or get a plain-English explanation powered by OpenRouter LLMs.

**Free to use** — works with free OpenRouter models at $0 cost.

---

## Features

| Feature | What it does |
|---|---|
| **Correct English** | Fixes grammar, spelling, and clarity. Corrected text is copied to your clipboard. |
| **Explain Text** | Shows a popup explaining jargon, idioms, or complex sentences in plain English. |
| **Works everywhere** | Any app: email, Slack, IDE, browser, notes, terminal. |
| **Keyboard shortcuts** | `Cmd+Shift+E` / `Cmd+Shift+X` on macOS. `Ctrl+Shift+E` / `Ctrl+Shift+X` on Linux. |
| **Free AI models** | Llama 3.3 70B, Gemini 2.0 Flash, DeepSeek R1/V3, Mistral 7B, Qwen 2.5, and more. |
| **Stop services** | Right-click → Stop Lexa Services to kill any running process. |

---

## macOS Installation

### Option A — DMG (Recommended)

1. Download `Lexa-1.0.0.dmg` from [Releases](https://github.com/ikppramesh/Lexa/releases)
2. Open the DMG and drag **Lexa.app** into `/Applications`
3. Open **Lexa** from Finder/Launchpad — it will guide you through first-run setup:
   - Enter your OpenRouter API key
   - Choose an AI model (free options available)
   - Quick Actions are installed automatically
4. Enable the services:
   - **System Settings → Keyboard → Shortcuts → Services → Text**
   - Check: `Correct English (Lexa)`, `Explain Text (Lexa)`, `Stop Lexa Services`
5. Select any text in any app → right-click → **Services** → **Correct English (Lexa)**

> **Re-run setup:** Simply open Lexa.app again from /Applications to re-enter your API key or change the model.

---

### Option B — From Source (Developer)

**Requirements:** Python 3.9+, Homebrew Python recommended (`/opt/homebrew/bin/python3`)

```bash
# 1. Clone
git clone https://github.com/ikppramesh/Lexa.git
cd Lexa

# 2. Run setup
bash mac/setup_mac.sh
```

The setup script:
- Installs Python dependencies (`requests`, `python-dotenv`, `pyperclip`)
- Creates `.env` from the template
- Registers Automator Quick Actions in `~/Library/Services/`
- Refreshes the macOS services cache

Then edit `.env` and set your API key:

```bash
# .env
OPENROUTER_API_KEY="sk-or-v1-xxxxxxxxxxxx"
CORRECTOR_MODEL=openrouter/free
CORRECTOR_TIMEOUT=30
CORRECTOR_MAX_CHARS=2000
```

Enable services in **System Settings → Keyboard → Shortcuts → Services → Text**.

---

## Linux (Ubuntu/GNOME) Installation

**Requirements:** Python 3.9+, GNOME desktop (for keyboard shortcuts), `xclip`, `libnotify-bin`, `python3-tk`

```bash
# 1. Clone
git clone https://github.com/ikppramesh/Lexa.git
cd Lexa

# 2. Run setup
bash linux/setup_linux.sh
```

The setup script:
- Installs system dependencies via `apt-get` (`xclip`, `libnotify-bin`, `python3-tk`)
- Installs Python dependencies
- Creates `.env` from the template
- Registers GNOME keyboard shortcuts: `Ctrl+Shift+E` (correct) and `Ctrl+Shift+X` (explain)

Then edit `.env` and set your API key:

```bash
nano .env
# Set OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxx
```

---

## Getting an API Key

1. Go to [openrouter.ai/keys](https://openrouter.ai/keys)
2. Sign up (free) and create an API key
3. Free-tier models cost **$0** — no credit card required for free models

---

## Choosing an AI Model

During setup (macOS DMG) or in `.env` (manual install), you can select a model:

### Free Models (Cost: $0)

| Model ID | Description |
|---|---|
| `openrouter/free` | Auto-picks the best available free model |
| `meta-llama/llama-3.3-70b-instruct:free` | Llama 3.3 70B — very capable |
| `google/gemini-2.0-flash-exp:free` | Gemini 2.0 Flash — fast & smart |
| `deepseek/deepseek-r1:free` | DeepSeek R1 — reasoning model |
| `deepseek/deepseek-v3:free` | DeepSeek V3 — strong general model |
| `mistralai/mistral-7b-instruct:free` | Mistral 7B — lightweight & fast |
| `meta-llama/llama-3.1-8b-instruct:free` | Llama 3.1 8B — quick responses |
| `qwen/qwen-2.5-72b-instruct:free` | Qwen 2.5 72B — multilingual |
| `microsoft/phi-3-mini-128k-instruct:free` | Phi-3 Mini — small & efficient |
| `google/gemma-3-12b-it:free` | Gemma 3 12B — Google's open model |
| `nvidia/nemotron-3-nano-30b-a3b:free` | Nemotron Nano 30B — NVIDIA's model |

### Paid Models

| Model ID | Description |
|---|---|
| `openai/gpt-4o-mini` | GPT-4o Mini — fast & affordable |
| `openai/gpt-4o` | GPT-4o — most capable OpenAI model |
| `anthropic/claude-haiku-4-5` | Claude Haiku — fast Anthropic model |

---

## How to Use

### macOS

1. **Select text** in any application
2. **Right-click** → **Services** → choose an action:
   - **Correct English (Lexa)** — corrects grammar/spelling, result copied to clipboard
   - **Explain Text (Lexa)** — shows a popup explaining the text
   - **Stop Lexa Services** — kills any running Lexa process
3. Or use keyboard shortcuts (after enabling in System Settings):
   - `Cmd+Shift+E` — Correct English
   - `Cmd+Shift+X` — Explain Text

> **After correction:** The corrected text is in your clipboard. Press `Cmd+V` to paste it over the original.

### Linux

1. **Select text** in any application (it is automatically in the clipboard on X11)
2. Press `Ctrl+Shift+E` to correct or `Ctrl+Shift+X` to explain
3. After correction, the corrected text is in your clipboard — press `Ctrl+V` to paste

---

## CLI Usage

You can also run Lexa directly from the terminal:

```bash
cd /path/to/Lexa

# Correct text from clipboard
python3 assistant.py --correct

# Explain text from clipboard
python3 assistant.py --explain

# Pipe text directly
echo "I didn't went there yesterday" | python3 assistant.py --correct

# Pipe text to explain
echo "The API returns a 429 status code" | python3 assistant.py --explain
```

---

## Configuration

All settings go in `.env` (or `~/Library/Application Support/Lexa/.env` for app installs):

| Variable | Default | Description |
|---|---|---|
| `OPENROUTER_API_KEY` | — | **Required.** Your OpenRouter API key |
| `CORRECTOR_MODEL` | `openrouter/free` | AI model to use (see model list above) |
| `CORRECTOR_TIMEOUT` | `30` | API timeout in seconds (free models can be slow) |
| `CORRECTOR_MAX_CHARS` | `2000` | Max input characters (hard cap: 5000) |
| `CORRECTOR_QUIET` | `0` | Set `1` to suppress desktop notifications |

Example `.env`:

```bash
OPENROUTER_API_KEY="sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
CORRECTOR_MODEL=meta-llama/llama-3.3-70b-instruct:free
CORRECTOR_TIMEOUT=30
CORRECTOR_MAX_CHARS=2000
```

---

## Project Structure

```
Lexa/
├── assistant.py              # CLI entry point (--correct / --explain)
├── openrouter_client.py      # OpenRouter API client with fallback chain
├── prompts.py                # Prompt templates for both modes
├── popup_ui.py               # Explanation popup + loading indicator
├── config.py                 # Environment variable config loader
├── notifications.py          # Cross-platform desktop notifications
├── requirements.txt          # Python dependencies
├── .env.example              # Config template
│
├── mac/                      # macOS integration
│   ├── setup_mac.sh          # One-shot macOS setup (source installs)
│   ├── correct_english_service.sh   # Automator Quick Action script
│   ├── explain_text_service.sh      # Automator Quick Action script
│   └── stop_lexa_services.sh        # Kill all running Lexa processes
│
├── linux/                    # Linux integration
│   ├── setup_linux.sh        # One-shot Ubuntu/GNOME setup
│   ├── correct_english.sh    # Keyboard shortcut script
│   └── explain_text.sh       # Keyboard shortcut script
│
├── build/                    # Build tooling
│   ├── mac/
│   │   ├── build_dmg.sh      # Builds Lexa.app + Lexa-1.0.0.dmg
│   │   └── lexa.icns         # App icon
│   └── linux/
│       ├── build_deb.sh      # Builds .deb package
│       └── lexa.desktop      # Desktop entry file
│
└── tests/                    # Unit tests (pytest)
    ├── test_assistant.py
    ├── test_api_client.py
    ├── test_prompts.py
    └── test_popup_ui.py
```

---

## Building the macOS DMG

```bash
# From the repo root
bash build/mac/build_dmg.sh
```

Output: `dist/Lexa-1.0.0.dmg`

Requirements: macOS with `hdiutil` (built-in), Python 3.9+

The build script:
1. Creates the `Lexa.app` bundle structure
2. Copies all Python scripts and service scripts into the bundle
3. Embeds the launcher that handles first-run setup
4. Packages the `.app` into a compressed DMG with an `/Applications` symlink

---

## Running Tests

```bash
cd Lexa
python3 -m pytest tests/ -v
```

All 30 unit tests should pass. Tests cover the API client, prompt generation, config loading, and UI helpers.

---

## Troubleshooting

### Services not appearing in right-click menu
- Open **System Settings → Keyboard → Shortcuts → Services → Text** and enable the Lexa services
- If they are missing entirely, re-open `Lexa.app` to re-install them, then run `/System/Library/CoreServices/pbs -update` in Terminal

### Spinner keeps running in menu bar
- Right-click → Services → **Stop Lexa Services**
- Or run in Terminal: `pkill -f assistant.py`

### "No API key" error
- Open `Lexa.app` again from /Applications — it will prompt you to enter the key
- Or edit `~/Library/Application Support/Lexa/.env` directly

### Slow responses / timeout
- Free OpenRouter models can take 10–30 seconds on cold starts
- If responses time out, increase `CORRECTOR_TIMEOUT=60` in your `.env`
- Switching to `openai/gpt-4o-mini` (paid, ~$0.0001/request) gives much faster responses

### macOS permission prompts
- On first use, macOS may ask for Accessibility / Automation permissions
- Grant permissions in **System Settings → Privacy & Security**

---

## License

MIT License — see [LICENSE](LICENSE) for details.
