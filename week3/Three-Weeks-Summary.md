# Three-week course summary

These notes summarize the three completed lab sections and the local Ollama adaptations.

## Week 1 — LLM foundations and APIs

- LLM applications are built from prompts, messages, model parameters, and a response loop.
- A direct HTTP client is useful for learning the API before adding orchestration frameworks.
- Prompt templates and structured outputs make repeatable tasks easier to test.
- Local Ollama keeps the same request/response shape while avoiding provider keys and per-call charges.

**Project 1 — `week1-ollama/01_technical_tutor_ollama.ipynb`**
Builds a technical tutor that answers questions, adapts explanations to a learner level, and produces short quizzes.
It demonstrates system prompts, conversation history, JSON parsing, and a local Ollama adapter.

**Project 2 — `week1-ollama/02_brochure_and_translation_ollama.ipynb`**
Creates a product brochure and translates it while preserving important facts and formatting.
It demonstrates reusable prompt templates, constrained fields, and a small local content workflow.

## Week 2 — Chatbots, Gradio, and tools

- Chat applications need explicit history, a system instruction, and a context-size policy.
- Gradio turns a Python callback into a usable local interface with little front-end code.
- Tool calling is an application loop: the model proposes an action, code validates it, and only code changes state.
- SQLite gives a local assistant durable, queryable state for business workflows.

**Project 1 — `week2-ollama/01_gradio_chatbot_ollama.ipynb`**
Builds a streaming local chatbot with a model selector, system prompt, and Gradio interface.
It demonstrates the same chat function in a notebook, a script-friendly adapter, and a UI.

**Project 2 — `week2-ollama/02_airline_tool_calling_ollama.ipynb`**
Builds an airline support agent with flight search, booking, lookup, and a deterministic SQLite store.
It demonstrates validated tool calls, tool results returned to the model, confirmation boundaries, and a local UI.

## Week 3 — Open-source GenAI and HuggingFace patterns

- Open-source models can run locally, keeping prompts and outputs under the learner's control.
- HuggingFace provides model discovery and task pipelines; this lab uses Ollama as the small local runtime.
- Ten common tasks share a pattern of clear instructions, constrained output, and validation.
- Audio products are pipelines: transcribe, extract decisions and actions, validate, and export.

**Project 1 — `week3-ollama/01_open_source_genai_ollama.ipynb`**
Runs ten common GenAI tasks such as summarization, translation, classification, extraction, Q&A, and agenda creation.
It shows how one local adapter and a few schemas can support many open-source model use cases.

**Project 2 — `week3-ollama/02_meeting_minutes_audio_ollama.ipynb`**
Turns a transcript into a title, summary, decisions, risks, and owner-based action items, then exports JSON and Markdown.
An optional `faster-whisper` hook accepts local audio while the default path stays lightweight and CPU-friendly.
