# Week 2 — Build a Multi-Modal Chatbot: LLMs, Gradio UI, and Agents

Course section: [Week 2 in the logged-in Udemy course](https://vodafoneegypt.udemy.com/course/llm-engineering-master-ai-and-large-language-models/learn/lecture/52939993#content)

The course section contains 24 lectures totaling about 3 hours 41 minutes. The curriculum moves from calling several model providers to building local and hosted chat experiences, then adds tool calling, databases, and multimodal UI patterns.

## Main ideas

- **Provider adapters:** OpenAI, Claude, and Gemini expose similar chat concepts but differ in authentication, model names, capabilities, and response details.
- **Reasoning models:** reasoning effort and scaling affect quality, latency, and cost; simple prompts are useful for comparing model behavior on puzzles and business questions.
- **Local inference:** Ollama provides a local model runtime, a native API, and an OpenAI-compatible endpoint. Local inference keeps prompts on the machine and removes per-call API cost, while model quality and speed depend on local hardware.
- **Framework choice:** LangChain provides orchestration abstractions; LiteLLM provides a common client surface across providers. A small direct HTTP adapter is often clearer for a focused application.
- **Gradio:** Python callbacks can become shareable data-science interfaces without writing a separate front end. Authentication, Markdown output, streaming, and multi-model controls are UI concerns around the same model function.
- **Chat state:** a chatbot needs explicit message history, system instructions, and a policy for how much history fits in the context window.
- **Prompting:** system prompts define behavior; few-shot examples show the desired format; early RAG ideas add external context instead of pretending the model has permanent memory.
- **Tool calling:** the model proposes a structured action, application code validates and executes it, and the tool result is sent back to the model for a final answer. The model must not directly mutate application state.
- **Multiple tools:** a useful agent selects among tools, handles tool errors, and can perform a sequence such as search → inspect → book. Confirmation should protect irreversible actions.
- **SQLite integration:** a local relational database gives an assistant durable, queryable state for flights, bookings, and other business workflows.
- **Multimodal applications:** the final lessons combine text chat with UI blocks, generated media, and tools. The cloud examples use provider APIs; the notebooks here keep the agent local and replace paid image APIs with a deterministic SVG result.

## Delivered projects

1. **`01_gradio_chatbot_ollama.ipynb`**
   - Direct Ollama `/api/chat` adapter.
   - Streaming and non-streaming calls.
   - Installed-model comparison.
   - Local Gradio chat interface with a model selector and system prompt.

2. **`02_airline_tool_calling_ollama.ipynb`**
   - Structured action selection with a deterministic fallback for small local models.
   - `search_flights`, `book_flight`, and `lookup_booking` tools backed by SQLite.
   - Tool result → Ollama final response loop.
   - Gradio chat interface and a local SVG flight card.

The notebooks are deliberately local-first. They do not reproduce the course's provider keys or paid API calls. They teach the same application patterns using Ollama and a small in-memory database. Use `llama3.2:1b` on a CPU machine; a larger local model generally improves structured actions and prose.


