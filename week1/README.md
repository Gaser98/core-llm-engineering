# Test Week 1 on an AWS CPU instance

[main.tf](main.tf) contains the complete Terraform configuration **and its EC2 user-data script**. It prepares a single-user, disposable lab; it has not been deployed to AWS account.

## What it creates

- **t3.large**, with 2 vCPUs and 8 GiB RAM, running **llama3.2:1b** on CPU. This uses the standard EC2 quota instead of the G/VT GPU quota. CPU inference is slower and the 1B model may follow complex brochure/translation instructions less reliably than 3B. [AWS specifications](https://docs.aws.amazon.com/ec2/latest/instancetypes/gp.html)
- Standard CPU credits avoid surplus-credit charges. Sustained inference can exhaust burst credits and reduce speed. `t3.xlarge` and `t3.2xlarge` are optional larger sizes.
- Canonical **Ubuntu Server 24.04 amd64**, resolved through its public SSM parameter. No NVIDIA drivers or GPU checks. [Ubuntu AMI documentation](https://documentation.ubuntu.com/aws/aws-how-to/instances/build-cloudformation-templates/)
- An encrypted **30 GiB gp3** root disk, VPC/subnet/internet gateway, and public IPv4 for outbound downloads. No inbound security-group rules or SSH keys.
- A private S3 bucket for locally detected notebooks; the instance role can read those objects. Missing notebooks can be uploaded through JupyterLab later.
- Ollama and JupyterLab systemd services bound to localhost. Startup pulls the selected model, copies the notebooks, updates their `MODEL` setting, and runs a real inference smoke test before recording `READY`.

## Steps

sudo cat /var/lib/week1-lab/status


sudo cat /home/lab/.jupyter-token


## Troubleshooting

sudo tail -n 100 /var/log/week1-bootstrap.log

- `FAILED ...` in status: inspect `/var/log/week1-bootstrap.log` and `/var/log/cloud-init-output.log`. `terraform apply` does not automatically retry a failed cloud-init installation.
- No SSM connection: check IAM instance-profile permissions, outbound connectivity, public IPv4, and Session Manager permissions/plugin installation. The selected AMI must include SSM Agent.
- Slow inference: CPU generation is expected to be slower. Use the 1B model, shorten prompts, and check EC2 CPU credit balance. Inspect `sudo journalctl -u ollama -n 100 --no-pager` if requests fail.
- Jupyter issue: `sudo systemctl status week1-jupyter` and `sudo journalctl -u week1-jupyter -n 80 --no-pager`.
- Once you fix a transient installation problem, this lab can be recreated with `terraform apply -replace=aws_instance.lab`. This discards the instance's local work, so download results first.
- AWS organization policies may forbid public IPv4 or internet gateways. This template is for a small internet-connected lab; it is not a private enterprise network deployment.

## Stop charges and remove the lab

This is an **On-Demand paid CPU instance**, not a free-tier deployment. EC2, EBS, public IPv4, S3, and any applicable data transfer are billed. There is **no automatic shutdown**. Review the selected region and instance price before applying. [AWS pricing](https://aws.amazon.com/ec2/pricing/on-demand/)

After downloading results, run from the same `aws` folder with the same credentials/settings:

```powershell
terraform destroy
```

## Implementation references

- [Ollama Linux installation and systemd](https://docs.ollama.com/linux)
- [Ollama chat API](https://docs.ollama.com/api/chat)
- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Validation

CPU bootstrap shell syntax and embedded Python were checked locally, including zero/one/two notebook download loops and cloud model-setting updates. No live AWS deployment or inference was performed for this CPU revision. Run `terraform init`, `terraform validate`, and a fresh plan in your AWS account before applying. Readiness checks on EC2 verify a real model response after installation.
