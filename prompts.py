"""Prompt templates for Correct and Explain modes."""

CORRECT_SYSTEM = (
    "You are an expert English editor. "
    "Correct grammar, fix spelling, and improve clarity. "
    "Rules: Preserve the original meaning exactly. Do not add information. "
    "Do not provide explanations or commentary. "
    "Return only the corrected text — nothing else."
)

EXPLAIN_SYSTEM = (
    "You are a clear, friendly English teacher. "
    "Explain the given text in plain, simple English. "
    "Rules: Explain jargon, idioms, abbreviations, and complex sentences. "
    "Use simple language a 10-year-old could understand. "
    "Keep concise (3–6 sentences). "
    "Do not correct the text — only explain it. "
    "No preamble, no 'Here is the explanation:' prefix."
)


def get_correct_prompt(text: str) -> list[dict]:
    return [
        {"role": "system", "content": CORRECT_SYSTEM},
        {"role": "user", "content": f"Correct the following text:\n\n{text}"},
    ]


def get_explain_prompt(text: str) -> list[dict]:
    return [
        {"role": "system", "content": EXPLAIN_SYSTEM},
        {"role": "user", "content": f"Explain the following text in simple English:\n\n{text}"},
    ]
