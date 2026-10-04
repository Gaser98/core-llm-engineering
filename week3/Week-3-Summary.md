# Week 3 — Open-Source Gen AI: Automated Solutions with HuggingFace

Course section: [Week 3 in the logged-in Udemy course](https://vodafoneegypt.udemy.com/course/llm-engineering-master-ai-and-large-language-models/learn/lecture/52939993#content)

## Main ideas

- Open-source models can run locally, keeping prompts and outputs under your control.
- HuggingFace provides model discovery, datasets, tokenizers, and task pipelines; Ollama is a lightweight local runtime for this lab.
- Common GenAI tasks share one pattern: clear instructions, constrained output, validation, and a small evaluation example.
- Structured JSON makes model output useful to application code instead of leaving every result as free-form text.
- Audio applications are pipelines: transcribe, extract decisions and actions, validate the result, then export it for people and systems.
- Small models are affordable on CPU, but prompt design and schema validation become more important as model size decreases.

## Projects

1. **`01_open_source_genai_ollama.ipynb`** — Runs ten practical use-case prompts (summary, translation, classification, extraction, Q&A, and more) through a single local adapter. It demonstrates the reusable prompt-and-validate pattern behind open-source model workflows.

2. **`02_meeting_minutes_audio_ollama.ipynb`** — Converts a transcript into a title, summary, decisions, risks, and owner-based action items, then saves JSON and Markdown. An optional `faster-whisper` hook accepts local audio while the default path stays small and CPU-friendly.

