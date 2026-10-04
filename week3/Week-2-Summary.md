# Week 2 — Build a Multi-Modal Chatbot: LLMs, Gradio UI, and Agents

Course section: [Week 2 in the logged-in Udemy course](https://vodafoneegypt.udemy.com/course/llm-engineering-master-ai-and-large-language-models/learn/lecture/52939993#content)

## Main ideas

- OpenAI, Claude, and Gemini expose similar chat concepts but differ in authentication, model names, capabilities, and response details.
- Ollama provides local inference through a native API and an OpenAI-compatible endpoint, avoiding per-call provider costs.
- A chatbot needs explicit message history, system instructions, and a policy for how much history fits the context window.
- Gradio turns Python callbacks into usable interfaces with streaming, Markdown, model selectors, and authentication options.
- Tool calling is an application loop: the model proposes a structured action, code validates and executes it, then the result goes back to the model.
- Multiple tools and confirmation boundaries make agents safer for workflows such as search, inspection, and booking.
- SQLite provides durable, queryable state for local business applications.
- Multimodal interfaces combine text, media, UI components, and tools; this local adaptation replaces paid image APIs with deterministic SVG output.

## Projects

1. **`01_gradio_chatbot_ollama.ipynb`** — Builds a streaming local chatbot with a model selector, system prompt, and Gradio interface.
It demonstrates the same chat function in a notebook, a script-friendly adapter, and a small UI.

2. **`02_airline_tool_calling_ollama.ipynb`** — Builds an airline support agent with flight search, booking, lookup, and a SQLite-backed store.
It demonstrates validated tool calls, tool results returned to the model, confirmation boundaries, and a local flight card UI.
