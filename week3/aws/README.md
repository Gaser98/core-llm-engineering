# Week 3 AWS CPU lab

This Terraform stack creates a disposable Ubuntu EC2 instance with no inbound ports. It installs Ollama, pulls `llama3.2:1b`, installs JupyterLab and the notebook dependencies, and copies the Week 3 notebooks from the parent folder through a private S3 bucket. Administration and Jupyter use AWS Systems Manager (SSM) tunnels.

## Deploy

Run these commands as the normal AWS-configured user from this `aws` directory:

```bash
terraform init
terraform apply
cat /var/lib/week3-lab/status   # on the instance, after opening an SSM shell
terraform output -raw ssm_shell_command
terraform output -raw jupyter_tunnel_command
```

The default is `t3.large` (2 vCPUs, 8 GiB RAM), an encrypted 30 GiB gp3 root volume, and `us-east-1`. Change `-var='region=...'` or `-var='instance_type=t3.xlarge'` if capacity is unavailable. This is CPU-only and does not request a GPU quota.

After the instance reports `READY`, open the tunnel command in a second terminal, browse to `http://127.0.0.1:8888/lab`, and read the token from the SSM shell with `sudo cat /home/lab/.jupyter-token`.

## Destroy

```bash
terraform destroy
```

The S3 bucket is marked `force_destroy` so uploaded notebook copies are removed with the lab.
