# Week 3 Ollama notebooks

These notebooks adapt Section 3, **Open-Source Gen AI: Automated Solutions with HuggingFace**, for a local Ollama runtime. They keep the course ideas practical on a CPU machine and avoid paid provider keys.

## Files

- `01_open_source_genai_ollama.ipynb` — ten common open-source GenAI use-case patterns using one local Ollama adapter.
- `02_meeting_minutes_audio_ollama.ipynb` — transcript/audio-to-meeting-minutes and action-items project with structured JSON and Markdown export.
- `Week-3-Summary.md` — concise section notes and the two project summaries.
- `aws/` — optional CPU EC2/Terraform lab that installs Ollama and JupyterLab and copies both notebooks.

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

4. Start Jupyter and open either notebook:

   ```bash
   python -m jupyter lab
   ```

The meeting notebook works immediately with pasted/transcribed text. Audio transcription is optional: install `faster-whisper`, set `USE_WHISPER = True`, and provide a local audio path. The default path never downloads a large speech model.

## AWS option

The [AWS guide](aws/README.md) and [Terraform configuration](aws/main.tf) use a standard CPU `t3.large`, Ubuntu Server, and `llama3.2:1b`; no NVIDIA quota is required. Run Terraform as your normal AWS-configured user, never with `sudo`.
