"""Repository checks that do not contact AWS or claim live validation."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


required_files = [
    "README.md",
    "docs/01-requirements.md",
    "docs/02-design.md",
    "docs/03-build-guide.md",
    "docs/04-test-plan.md",
    "docs/05-operations.md",
    "docs/06-incident-response.md",
    "docs/07-evidence-guide.md",
    "terraform/network.tf",
    "terraform/security.tf",
    "terraform/compute.tf",
    "terraform/monitoring.tf",
]
for relative in required_files:
    require((ROOT / relative).is_file(), f"missing required file: {relative}")

markdown_files = list(ROOT.glob("*.md")) + list((ROOT / "docs").rglob("*.md"))
for markdown_file in markdown_files:
    text = markdown_file.read_text(encoding="utf-8")
    for target in re.findall(r"\[[^]]+\]\(([^)]+)\)", text):
        if target.startswith(("http://", "https://", "#")):
            continue
        relative_target = target.split("#", 1)[0]
        resolved = (markdown_file.parent / relative_target).resolve()
        require(resolved.exists(), f"broken local link in {markdown_file.relative_to(ROOT)}: {target}")

tf_text = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "terraform").glob("*.tf"))
readme = (ROOT / "README.md").read_text(encoding="utf-8")

require('required_version = ">= 1.6.0"' in tf_text, "Terraform minimum version is not pinned")
require('version = "~> 5.0"' in tf_text, "AWS provider major version is not constrained")
require('http_tokens                 = "required"' in tf_text, "IMDSv2 is not required")
require("associate_public_ip_address = false" in tf_text, "EC2 public IP is not explicitly disabled")
require("encrypted             = true" in tf_text, "root EBS encryption is not enabled")
require('health_check_type         = "ELB"' in tf_text, "ASG does not use ELB health checks")
require("NOT RUN" in readme, "README must distinguish unexecuted live work")

ssh_ingress = re.search(r"from_port\s*=\s*22", tf_text)
require(ssh_ingress is None, "TCP/22 ingress was found")

tracked_sensitive_patterns = ["*.tfstate", "*.tfplan", "*.pem", "*.key"]
gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
for pattern in tracked_sensitive_patterns:
    require(pattern in gitignore, f".gitignore is missing {pattern}")

if errors:
    for error in errors:
        print(f"ERROR: {error}")
    sys.exit(1)

print(f"PASS: {len(required_files)} required files and security invariants checked")
print("NOTE: AWS plan/apply and live tests were NOT RUN by this script")
