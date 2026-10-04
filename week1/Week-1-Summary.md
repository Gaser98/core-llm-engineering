# Week 1 — Build Your First LLM Product

Course section: [Week 1 in the logged-in Udemy course](https://vodafoneegypt.udemy.com/course/llm-engineering-master-ai-and-large-language-models/learn/lecture/52933079#content)

## Main ideas

- An LLM application combines prompts, ordered messages, a model call, and a response-handling loop.
- HTTP endpoints, SDKs, OpenAI-compatible APIs, and Ollama use similar chat concepts but differ in models, capabilities, speed, and cost.
- System prompts define behavior; user messages provide the task and bounded context.
- Tokens determine context use, latency, and cost, while application memory comes from resending selected history.
- Base, chat/instruct, reasoning, frontier, open-weight, and local models have different strengths and tradeoffs.
- Transformers use attention to relate tokens; model size alone does not guarantee better task performance.
- Reliable applications validate JSON, bound scraped text, preserve source data, and separate retrieval from generation.
- Chained calls and streaming support useful products such as brochure generators, tutors, and translation workflows.

## Projects

1. **`01_technical_tutor_ollama.ipynb`** — Builds a technical tutor that answers questions, adapts explanations to learner level, and produces short quizzes.
It demonstrates system prompts, conversation history, structured output parsing, and a local Ollama backend.

2. **`02_brochure_and_translation_ollama.ipynb`** — Creates a product brochure and translates it while preserving important facts and formatting.
It demonstrates bounded content, reusable prompt templates, chained generation, and source/translation export.
