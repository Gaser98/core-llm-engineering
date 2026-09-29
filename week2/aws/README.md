# Test Week 2 on an AWS CPU instance

This is a disposable CPU lab for the Week 2 Ollama notebooks. It uses `t3.large` by default, installs Ubuntu Server 24.04, Ollama, JupyterLab, Requests, and Gradio, then runs a local Ollama smoke test. It does not require a GPU quota.

## Folder layout

Put `main.tf` and these two notebooks in the same `week2` folder:

```text
week2/
  main.tf
  01_gradio_chatbot_ollama.ipynb
  02_airline_tool_calling_ollama.ipynb
```

The configuration detects notebooks beside `main.tf` first. It also checks the parent folder for compatibility. Missing notebooks do not prevent Terraform planning; they can be uploaded through JupyterLab after the instance becomes ready.

## Deploy

Use a normal terminal with AWS credentials and run these commands from the folder containing `main.tf`:

```bash
terraform init
terraform validate
terraform plan -out=lab.tfplan
terraform apply lab.tfplan
```

Do not run Terraform with `sudo`; it creates root-owned state and provider files. The defaults are:

```hcl
instance_type   = "t3.large"
model           = "llama3.2:1b"
root_volume_gib = 30
```

You can override them in `terraform.tfvars`. `t3.xlarge` and `t3.2xlarge` provide more CPU/RAM for faster generation. CPU inference is slower than a GPU, but the 1B model is suitable for this lab.

## Connect

The EC2 instance has no inbound security-group rules. Use Session Manager from your own computer:

```bash
terraform output -raw ssm_shell_command
terraform output -raw jupyter_tunnel_command
```

Run the shell command in one terminal and wait for:

```bash
sudo cat /var/lib/week2-lab/status
```

When it says `READY`, retrieve the token:

```bash
sudo cat /home/lab/.jupyter-token
```

In a second local terminal, run the tunnel command and leave it open. Then open [http://127.0.0.1:8888/lab](http://127.0.0.1:8888/lab), enter the token, and open either notebook. If the AWS CLI says `SessionManagerPlugin is not found`, install the plugin on your local computer using the [AWS instructions](https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html).

The identity running the local `aws ssm start-session` command needs `ssm:StartSession`; the EC2 instance role is used by the SSM agent and is not the identity for your local tunnel.

## Verify and destroy

Inside the EC2 shell:

```bash
sudo ls -lah /home/lab/notebooks
sudo systemctl is-active ollama
sudo systemctl is-active week2-jupyter
```

The notebook directory is owned by the `lab` user, so `sudo` is expected for inspection from the SSM shell. After downloading results, destroy the lab from the same local Terraform folder:

```bash
terraform destroy
```

This is a paid On-Demand EC2 instance. There is no automatic shutdown.

## Scope and validation

The notebooks and bootstrap script were checked for valid JSON/Python and the SQLite tool path was tested locally. No AWS resources are created by preparing these files. A live boot still depends on your AWS credentials, regional capacity, quota, network access, and package/model downloads.
