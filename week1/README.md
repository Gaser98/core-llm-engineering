# Test Week 1 on an AWS CPU instance

[main.tf](main.tf) contains the complete Terraform configuration **and its EC2 user-data script**. It prepares a single-user, disposable lab; it has not been deployed to your AWS account.

## What it creates

- **t3.large**, with 2 vCPUs and 8 GiB RAM, running **llama3.2:1b** on CPU. This uses the standard EC2 quota instead of the G/VT GPU quota. CPU inference is slower and the 1B model may follow complex brochure/translation instructions less reliably than 3B. [AWS specifications](https://docs.aws.amazon.com/ec2/latest/instancetypes/gp.html)
- Standard CPU credits avoid surplus-credit charges. Sustained inference can exhaust burst credits and reduce speed. `t3.xlarge` and `t3.2xlarge` are optional larger sizes.
- Canonical **Ubuntu Server 24.04 amd64**, resolved through its public SSM parameter. No NVIDIA drivers or GPU checks. [Ubuntu AMI documentation](https://documentation.ubuntu.com/aws/aws-how-to/instances/build-cloudformation-templates/)
- An encrypted **30 GiB gp3** root disk, VPC/subnet/internet gateway, and public IPv4 for outbound downloads. No inbound security-group rules or SSH keys.
- A private S3 bucket for locally detected notebooks; the instance role can read those objects. Missing notebooks can be uploaded through JupyterLab later.
- Ollama and JupyterLab systemd services bound to localhost. Startup pulls the selected model, copies the notebooks, updates their `MODEL` setting, and runs a real inference smoke test before recording `READY`.

## Updating an existing GPU configuration

Replace your existing `main.tf` with this file and keep your notebooks and Terraform state. If you have `terraform.tfvars`, change `instance_type` to `"t3.large"`, `model` to `"llama3.2:1b"`, and `root_volume_gib` to `30`. Remove any old GPU `ami_id` override (or set it to `null`) so Terraform chooses Ubuntu Server. Environment variables and CLI `-var` arguments can also override these defaults.

Create a fresh plan; do not apply an older saved GPU plan. Existing networking and S3 resources can be reused. If an instance already exists, the AMI/user-data changes replace it: download its local work first. Review any subnet/AZ changes in the plan as the automatic selection now considers T3 offerings.

Your browser runs locally, while the notebook kernel and Ollama run together on EC2. Keep `OLLAMA_URL = "http://127.0.0.1:11434"` in the notebooks—it refers to EC2 from that kernel. No OpenAI key is needed.

## 1. Prepare and deploy

You can deploy with **only `main.tf`** in your `week1` directory. Missing notebooks no longer prevent planning or startup; upload them through JupyterLab after installation. For automatic upload, place either or both notebooks beside `main.tf`, or use the original layout below. Files beside `main.tf` take priority over copies in its parent directory.

```text
week1-ollama/
  01_technical_tutor_ollama.ipynb
  02_brochure_and_translation_ollama.ipynb
  aws/
    main.tf
    README.md
```

On your computer, install Terraform 1.6+, AWS CLI v2, and the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). Configure AWS credentials for your account, for example using your usual AWS SSO profile. The deploying identity needs EC2/VPC, S3, IAM role/profile creation and `iam:PassRole`, plus read access to the public SSM AMI parameter. Your session identity also needs permission to start/terminate SSM sessions and use the port-forwarding document.

The regional **Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances** quota needs at least 2 available vCPUs for `t3.large`. A zero GPU quota does not block this instance, but account restrictions and standard quotas still apply. [EC2 quotas](https://docs.aws.amazon.com/ec2/latest/instancetypes/ec2-instance-quotas.html)

From the directory containing `main.tf` (your `week1` directory, or this `aws` folder):

```powershell
aws sts get-caller-identity
terraform init
terraform fmt -check
terraform validate
terraform plan -out=lab.tfplan
terraform apply lab.tfplan
```

The default region is `us-east-1`. To change settings, create `terraform.tfvars` before planning, for example:

```hcl
region        = "us-east-1"
instance_type = "t3.large"
model         = "llama3.2:1b"
# availability_zone = "us-east-1a"  # Optional; normally selected from offerings.
# ami_id = "ami-..."               # Optional pinned Ubuntu 24.04 amd64 AMI.
```

`t3.xlarge` and `t3.2xlarge` provide more CPU/RAM. `llama3.2:3b` remains an optional model with better capability but slower CPU generation. Startup updates automatically copied notebooks to your chosen model; for manually uploaded notebooks, set `MODEL = "llama3.2:1b"` yourself (or your chosen model).

The outputs `notebooks_uploaded` and `notebooks_to_upload_manually` show which files were found. After deployment, use JupyterLab upload for missing notebooks; adding local files and applying Terraform later replaces the instance.

Terraform finishing does **not** mean installation has finished. Allow time for package/model downloads. Keep Terraform state and any `.tfvars` file until you destroy the lab. Changes to user data or local notebook files replace this disposable instance, so download your work first. The latest-AMI lookup can also select a newer image on a later plan; use `ami_id` to pin the observed output if needed.

## 2. Check installation and retrieve the Jupyter token

Print the connection command:

```powershell
terraform output -raw ssm_shell_command
```

Copy and run that command in your terminal. If the instance is not yet registered with SSM, wait briefly and retry. Inside the EC2 shell:

```bash
sudo cat /var/lib/week1-lab/status
sudo tail -n 60 /var/log/week1-bootstrap.log
```

Wait for `READY`. Then retrieve the login token:

```bash
sudo cat /home/lab/.jupyter-token
```

The random token is generated on EC2, not embedded in Terraform or its state. Copy it privately for the Jupyter login. The token stays the same across instance restarts.

## 3. Open the notebooks

In a second local terminal:

```powershell
terraform output -raw jupyter_tunnel_command
```

Copy and run the printed command. It uses `AWS-StartPortForwardingSession` to forward local port **8888** to EC2 port **8888**. Leave this terminal open. If 8888 is already in use locally, change only `localPortNumber=8888` to `localPortNumber=8889` in that command and use port 8889 in the browser. [AWS port-forwarding documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html)

Open [JupyterLab](http://127.0.0.1:8888/lab), paste the token, then open either notebook and select the **Python 3** kernel. Choose **Run → Run All Cells**.

If the file browser is empty, use its **Upload Files** button to upload [the tutor notebook](../01_technical_tutor_ollama.ipynb) and [the brochure and translation notebook](../02_brochure_and_translation_ollama.ipynb) from your computer, then open them. No Terraform re-apply is needed.

- Tutor: edit `QUESTION`, learner background, and style; rerun to get a streamed answer.
- Brochure: start with `USE_SAMPLE_SITE = True`. This uses fictional source pages but real inference on your AWS CPU. It performs link selection, brochure generation, and translation. For a real site, switch to `False` and supply its company name and canonical URL.
- Results are saved in the notebook's `results/` folder. Use JupyterLab's file browser to download the generated Markdown and any modified notebooks before terminating EC2.

To inspect the CPU model and startup test from an SSM shell:

```bash
ollama ps
cat /var/lib/week1-lab/smoke.json
```

You do not need to install Ollama on your laptop for this workflow.

## Troubleshooting

- `FAILED ...` in status: inspect `/var/log/week1-bootstrap.log` and `/var/log/cloud-init-output.log`. `terraform apply` does not automatically retry a failed cloud-init installation.
- No SSM connection: check IAM instance-profile permissions, outbound connectivity, public IPv4, and Session Manager permissions/plugin installation. The selected AMI must include SSM Agent.
- Slow inference: CPU generation is expected to be slower. Use the 1B model, shorten prompts, and check EC2 CPU credit balance. Inspect `sudo journalctl -u ollama -n 100 --no-pager` if requests fail.
- Jupyter issue: `sudo systemctl status week1-jupyter` and `sudo journalctl -u week1-jupyter -n 80 --no-pager`.
- Once you fix a transient installation problem, this lab can be recreated with `terraform apply -replace=aws_instance.lab`. This discards the instance's local work, so download results first.
- AWS organization policies may forbid public IPv4 or internet gateways. This template is for a small internet-connected lab; it is not a private enterprise network deployment.

## 4. Stop charges and remove the lab

This is an **On-Demand paid CPU instance**, not a free-tier deployment. EC2, EBS, public IPv4, S3, and any applicable data transfer are billed. There is **no automatic shutdown**. Review the selected region and instance price before applying. [AWS pricing](https://aws.amazon.com/ec2/pricing/on-demand/)

After downloading results, run from the same `aws` folder with the same credentials/settings:

```powershell
terraform destroy
```

Destroy removes the EC2 instance and root disk, this lab's S3 assets, IAM resources, and networking. The asset bucket uses `force_destroy = true`; do not store unrelated files in it. Closing Jupyter or the SSM tunnel does not stop EC2. Stopping EC2 stops compute charges but retains billable EBS storage.

## Implementation references

- [Ollama Linux installation and systemd](https://docs.ollama.com/linux)
- [Ollama chat API](https://docs.ollama.com/api/chat)
- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Validation

CPU bootstrap shell syntax and embedded Python were checked locally, including zero/one/two notebook download loops and cloud model-setting updates. No live AWS deployment or inference was performed for this CPU revision. Run `terraform init`, `terraform validate`, and a fresh plan in your AWS account before applying. Readiness checks on EC2 verify a real model response after installation.
