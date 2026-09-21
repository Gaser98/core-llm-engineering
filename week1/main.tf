# Notebooks are optional: detected beside main.tf first, then in its parent folder.
# This creates a disposable CPU lab. Nothing is deployed until terraform apply.
terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.66.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = "week1-ollama", ManagedBy = "terraform" }
  }
}

variable "region" {
  description = "Commercial AWS region with standard EC2 capacity and Canonical Ubuntu AMIs."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "CPU-only x86 instance. Default t3.large has 2 vCPUs and 8 GiB RAM for the 1B model."
  type        = string
  default     = "t3.large"
  validation {
    condition     = contains(["t3.large", "t3.xlarge", "t3.2xlarge"], var.instance_type)
    error_message = "Use t3.large, t3.xlarge, or t3.2xlarge (x86 CPU)."
  }
}

variable "availability_zone" {
  description = "Optional AZ override; otherwise choose an available AZ offering the instance type."
  type        = string
  default     = null
}

variable "ami_id" {
  description = "Optional pinned Canonical Ubuntu Server 24.04 amd64 AMI. Null resolves its public SSM parameter."
  type        = string
  default     = null
}

variable "model" {
  description = "Local Ollama model to pull at boot. This value is also applied to the notebook configuration."
  type        = string
  default     = "llama3.2:1b"
  validation {
    condition     = contains(["llama3.2:3b", "llama3.2:1b"], var.model)
    error_message = "This lab is tested structurally for llama3.2:3b or llama3.2:1b."
  }
}

variable "root_volume_gib" {
  description = "Encrypted gp3 root volume, including OS, notebooks, and Ollama model storage."
  type        = number
  default     = 30
  validation {
    condition     = var.root_volume_gib >= 30 && floor(var.root_volume_gib) == var.root_volume_gib
    error_message = "Use an integer of at least 30 GiB for Ubuntu and model files."
  }
}

data "aws_partition" "current" {}

data "aws_ssm_parameter" "ubuntu" {
  count = var.ami_id == null ? 1 : 0
  name  = "/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ec2_instance_type_offerings" "cpu" {
  location_type = "availability-zone"
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
  filter {
    name   = "location"
    values = data.aws_availability_zones.available.names
  }
}

locals {
  ami = var.ami_id != null ? var.ami_id : nonsensitive(data.aws_ssm_parameter.ubuntu[0].value)
  az  = var.availability_zone != null ? var.availability_zone : try(sort(tolist(data.aws_ec2_instance_type_offerings.cpu.locations))[0], "")
  notebook_names = toset([
    "01_technical_tutor_ollama.ipynb",
    "02_brochure_and_translation_ollama.ipynb"
  ])
  notebook_candidates = {
    for name in local.notebook_names : name => fileexists("${path.module}/${name}") ? "${path.module}/${name}" : "${path.module}/../${name}"
  }
  notebooks = { for name, source in local.notebook_candidates : name => source if fileexists(source) }
  # Only hash files that exist. Adding/removing/changing one replaces this disposable instance.
  notebook_hash = sha256(join("", [for name in sort(keys(local.notebooks)) : "${name}:${filesha256(local.notebooks[name])}"]))
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.86.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "week1-ollama" }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
}

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.86.1.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = true
  tags                    = { Name = "week1-ollama" }
  lifecycle {
    precondition {
      condition     = local.az != "" && contains(data.aws_ec2_instance_type_offerings.cpu.locations, local.az)
      error_message = "No matching CPU instance offering in this AZ/region. Change region, availability_zone, or instance_type."
    }
  }
}

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
}

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

resource "aws_security_group" "lab" {
  name_prefix = "week1-ollama-"
  description = "No inbound access. Administration and Jupyter use SSM tunnels."
  vpc_id      = aws_vpc.lab.id
  ingress     = []
  egress {
    description = "Package/model downloads and outbound AWS SSM connectivity"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Private assets avoid EC2's 16 KiB user-data limit for any notebooks found locally.
resource "aws_s3_bucket" "assets" {
  bucket_prefix = "week1-ollama-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "notebook" {
  for_each               = local.notebooks
  bucket                 = aws_s3_bucket.assets.id
  key                    = "notebooks/${each.key}"
  source                 = each.value
  etag                   = filemd5(each.value)
  content_type           = "application/x-ipynb+json"
  server_side_encryption = "AES256"
  depends_on             = [aws_s3_bucket_public_access_block.assets]
}

resource "aws_iam_role" "lab" {
  name_prefix = "week1-ollama-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.lab.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "notebooks" {
  count = length(local.notebooks) > 0 ? 1 : 0
  role  = aws_iam_role.lab.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = [for name in keys(local.notebooks) : "${aws_s3_bucket.assets.arn}/notebooks/${name}"]
    }]
  })
}

resource "aws_iam_instance_profile" "lab" {
  name_prefix = "week1-ollama-"
  role        = aws_iam_role.lab.name
}

resource "aws_instance" "lab" {
  ami                         = local.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.lab.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.lab.id]
  iam_instance_profile        = aws_iam_instance_profile.lab.name
  user_data_replace_on_change = true
  # Standard credits avoid surplus CPU-credit charges; sustained load can throttle.
  credit_specification {
    cpu_credits = "standard"
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_gib
    encrypted             = true
    delete_on_termination = true
  }
  tags = { Name = "week1-ollama-cpu" }

  user_data = <<-USERDATA
    #!/bin/bash
    set -Eeuo pipefail
    exec > >(tee -a /var/log/week1-bootstrap.log) 2>&1
    install -d /var/lib/week1-lab
    trap 'echo "FAILED at line $LINENO" > /var/lib/week1-lab/status' ERR
    echo INSTALLING > /var/lib/week1-lab/status
    # Asset revision: ${local.notebook_hash}
    # cloud-init can omit HOME; the Ollama CLI requires it even for remote API calls.
    export HOME=/root
    export DEBIAN_FRONTEND=noninteractive
    export AWS_DEFAULT_REGION='${var.region}'
    export AWS_PAGER=""

    retry() {
      local attempt
      for attempt in 1 2 3 4 5; do
        if "$@"; then return 0; fi
        sleep 10
      done
      return 1
    }

    # Official Ubuntu Server AMIs include SSM Agent.
    if systemctl cat amazon-ssm-agent.service >/dev/null 2>&1; then
      systemctl enable --now amazon-ssm-agent
    elif systemctl cat snap.amazon-ssm-agent.amazon-ssm-agent.service >/dev/null 2>&1; then
      systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent
    else
      echo "Expected SSM Agent missing from selected Ubuntu AMI" >&2
      false
    fi
    retry apt-get update
    retry apt-get install -y curl ca-certificates python3-venv unzip zstd
    if ! command -v aws >/dev/null; then
      curl --fail --location --retry 5 https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscli.zip
      unzip -q -o /tmp/awscli.zip -d /tmp/week1-awscli
      /tmp/week1-awscli/aws/install --update
    fi

    # Official installer creates and enables the Ollama systemd service.
    curl --fail --location --retry 5 https://ollama.com/install.sh -o /tmp/install-ollama.sh
    sh /tmp/install-ollama.sh
    install -d /etc/systemd/system/ollama.service.d
    cat > /etc/systemd/system/ollama.service.d/week1.conf <<'OLLAMA'
    [Service]
    Environment="OLLAMA_HOST=127.0.0.1:11434"
    Environment="OLLAMA_CONTEXT_LENGTH=8192"
    Environment="OLLAMA_NUM_PARALLEL=1"
    Environment="OLLAMA_MAX_LOADED_MODELS=1"
    OLLAMA
    systemctl daemon-reload
    systemctl enable ollama
    systemctl restart ollama
    export OLLAMA_HOST=http://127.0.0.1:11434
    retry curl --fail --silent http://127.0.0.1:11434/api/tags
    retry ollama pull '${var.model}'

    # A dedicated non-root notebook user; no credentials are embedded in Terraform.
    id lab >/dev/null 2>&1 || useradd --create-home --shell /bin/bash lab
    install -d -o lab -g lab /home/lab/notebooks
    python3 -m venv /opt/week1-venv
    /opt/week1-venv/bin/pip install --disable-pip-version-check 'jupyterlab>=4,<5' 'ipykernel>=6,<8'
    echo 'Staging ${length(local.notebooks)} notebook(s). Missing notebooks can be uploaded through JupyterLab.'
    notebooks=(${join(" ", sort(keys(local.notebooks)))})
    for file in "$${notebooks[@]}"; do
      retry aws s3 cp "s3://${aws_s3_bucket.assets.id}/notebooks/$file" "/home/lab/notebooks/$file" --only-show-errors
    done
    export WEEK1_MODEL='${var.model}'
    python3 - <<'PY'
    import json, os
    from pathlib import Path
    for path in Path('/home/lab/notebooks').glob('*.ipynb'):
        data = json.loads(path.read_text())
        for cell in data['cells']:
            if cell['cell_type'] == 'code':
                cell['source'] = [f"MODEL = {os.environ['WEEK1_MODEL']!r}\n" if line.startswith('MODEL = ') else line for line in cell['source']]
        path.write_text(json.dumps(data, indent=2), encoding='utf-8')
    PY

    # Generate the Jupyter token on the instance (not in Terraform state/user data).
    if [ ! -s /home/lab/.jupyter-token ]; then
      (umask 077; python3 -c 'import secrets; print(secrets.token_urlsafe(32))' > /home/lab/.jupyter-token)
    fi
    cat > /home/lab/jupyter_config.py <<'JUPYTER'
    from pathlib import Path
    c = get_config()
    c.ServerApp.ip = '127.0.0.1'
    c.ServerApp.port = 8888
    c.ServerApp.port_retries = 0
    c.ServerApp.open_browser = False
    c.ServerApp.root_dir = '/home/lab/notebooks'
    c.IdentityProvider.token = Path('/home/lab/.jupyter-token').read_text().strip()
    JUPYTER
    chmod 600 /home/lab/.jupyter-token /home/lab/jupyter_config.py
    chown -R lab:lab /home/lab
    cat > /etc/systemd/system/week1-jupyter.service <<'SERVICE'
    [Unit]
    Description=Week 1 JupyterLab
    Wants=network-online.target
    After=network-online.target ollama.service
    [Service]
    Type=simple
    User=lab
    Group=lab
    WorkingDirectory=/home/lab/notebooks
    Environment="HOME=/home/lab"
    ExecStart=/opt/week1-venv/bin/jupyter lab --config=/home/lab/jupyter_config.py
    Restart=on-failure
    RestartSec=5
    UMask=0077
    [Install]
    WantedBy=multi-user.target
    SERVICE
    systemctl daemon-reload
    systemctl enable --now week1-jupyter

    # Run one real CPU inference before declaring readiness.
    curl --fail --silent --show-error --max-time 600 http://127.0.0.1:11434/api/chat \
      -H 'Content-Type: application/json' \
      -d '{"model":"${var.model}","messages":[{"role":"user","content":"Reply with the word ready."}],"stream":false,"keep_alive":"10m","options":{"num_predict":16,"num_ctx":8192}}' \
      -o /var/lib/week1-lab/smoke.json
    python3 - <<'PY'
    import json
    from pathlib import Path
    result = json.loads(Path('/var/lib/week1-lab/smoke.json').read_text())
    assert result.get('done') and result.get('message', {}).get('content', '').strip(), 'No complete model response'
    PY
    retry curl --fail --silent --output /dev/null http://127.0.0.1:8888/login
    echo READY > /var/lib/week1-lab/status
    echo 'Ready: use an SSM shell to read /home/lab/.jupyter-token, and forward port 8888.'
  USERDATA

  depends_on = [
    aws_route_table_association.lab,
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy.notebooks,
    aws_s3_object.notebook
  ]
}

output "instance_id" {
  value = aws_instance.lab.id
}

output "notebooks_uploaded" {
  value = sort(keys(local.notebooks))
}

output "notebooks_to_upload_manually" {
  description = "Files absent locally. Upload these through JupyterLab after installation is READY."
  value       = sort(tolist(setsubtract(local.notebook_names, toset(keys(local.notebooks)))))
}

output "ami_id" {
  value = local.ami
}

output "ssm_shell_command" {
  value = "aws ssm start-session --region ${var.region} --target ${aws_instance.lab.id}"
}

output "jupyter_tunnel_command" {
  value = "aws ssm start-session --region ${var.region} --target ${aws_instance.lab.id} --document-name AWS-StartPortForwardingSession --parameters \"portNumber=8888,localPortNumber=8888\""
}

output "jupyter_url" {
  value = "http://127.0.0.1:8888/lab (enter the token read over the SSM shell)"
}
