#!/usr/bin/env python3
"""Rewrites the language switcher at the top of README.md and docs/README.<code>.md.

Run after adding or editing a translation: ./scripts/readme-langs.py
"""
import re, pathlib

LANGS = [  # (code, flag, native name); "en" is the root README
    ("en", "🇬🇧", "English"), ("ru", "🇷🇺", "Русский"), ("uk", "🇺🇦", "Українська"), ("de", "🇩🇪", "Deutsch"),
    ("fr", "🇫🇷", "Français"), ("es", "🇪🇸", "Español"), ("pt-PT", "🇵🇹", "Português"), ("pt-BR", "🇧🇷", "Português (Brasil)"),
    ("pl", "🇵🇱", "Polski"), ("cs", "🇨🇿", "Čeština"), ("hu", "🇭🇺", "Magyar"), ("tr", "🇹🇷", "Türkçe"),
    ("kk", "🇰🇿", "Қазақша"), ("hi", "🇮🇳", "हिन्दी"), ("ja", "🇯🇵", "日本語"), ("zh-Hans", "🇨🇳", "简体中文"), ("zh-Hant", "🇹🇼", "繁體中文"),
]
ROOT = pathlib.Path(__file__).resolve().parent.parent

def path_for(code, relative_to_docs):
    if code == "en":
        return "../README.md" if relative_to_docs else "README.md"
    return f"README.{code}.md" if relative_to_docs else f"docs/README.{code}.md"

def switcher(current):
    in_docs = current != "en"
    parts = []
    for code, flag, name in LANGS:
        label = f"{flag} {name}"
        parts.append(f"**{label}**" if code == current else f"[{label}]({path_for(code, in_docs)})")
    return "<!-- LANGS -->\n" + " · ".join(parts) + "\n<!-- /LANGS -->"

for code, _, _ in LANGS:
    p = ROOT / ("README.md" if code == "en" else f"docs/README.{code}.md")
    if not p.exists():
        print("missing", p); continue
    text = p.read_text()
    block = switcher(code)
    if "<!-- LANGS -->" in text:
        text = re.sub(r"<!-- LANGS -->.*?(<!-- /LANGS -->|\n)", block + "\n", text, count=1, flags=re.S) if "<!-- /LANGS -->" in text \
            else text.replace("<!-- LANGS -->", block, 1)
    else:
        text = block + "\n\n" + text
    p.write_text(text)
    print("updated", p.relative_to(ROOT))
