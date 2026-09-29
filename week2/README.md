# Week 2 Ollama notebooks

These notebooks adapt Section 2 of the course, **Build a Multi-Modal Chatbot: LLMs, Gradio UI, and Agents**, for a local Ollama runtime.

## Files

- `01_gradio_chatbot_ollama.ipynb` — model adapter, streaming, model comparison, and Gradio chat UI.
- `02_airline_tool_calling_ollama.ipynb` — SQLite flight tools, structured action selection, agent loop, Gradio UI, and an SVG flight card.
- `Week-2-Summary.md` — bullet summary and the mapping from course themes to the projects.
- `aws/` — optional CPU EC2/Terraform lab that installs Ollama, JupyterLab, Requests, and Gradio and copies both notebooks.

## Run locally

1. Install Ollama from [ollama.com/download](https://ollama.com/download).
2. Pull a small model:

   ```bash
   ollama pull llama3.2:1b
   ```

3. Install notebook dependencies:

   ```bash
   python -m pip install jupyterlab requests 'gradio>=5,<6'
   ```

4. Start Jupyter:

   ```bash
   python -m jupyter lab
   ```

5. Open a notebook, select a Python 3 kernel, run the setup cells, and confirm the Ollama health check succeeds. Set `RUN_UI = True` only in the final UI cell when you want the Gradio app to launch.

The default endpoint is `http://127.0.0.1:11434`. Change `MODEL` if you already have another Ollama model installed. The airline notebook uses an in-memory SQLite database, so its bookings reset when the kernel restarts.

## AWS option

The [AWS guide](aws/README.md) and [Terraform configuration](aws/main.tf) use a standard CPU `t3.large`, Ubuntu Server, and `llama3.2:1b`; no NVIDIA quota is required. They install the notebook dependencies, upload notebooks found beside `main.tf`, and expose Jupyter only through an SSM port-forwarding tunnel. Run Terraform as your normal AWS-configured user, never with `sudo`.
