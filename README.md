# Valkey Benchmark Tools

This project automates Valkey vs. memtier benchmarks on AWS using
Terraform, Ansible, Python and Bash.

## Prerequisites
- Terraform >= 1.3
- Ansible
- Python 3.11
- AWS credentials with permissions to launch EC2 instances
- Existing VPC and subnet IDs
- Path to your SSH public key

## Quick start
```bash
python scripts/run_benchmarks.py \
  --server t3.micro \
  --client t3.micro \
  --io-threads 1 4 \
  --key ~/.ssh/id_rsa.pub \
  --vpc vpc-xxxx \
  --subnet subnet-xxxx \
  --region us-east-1
```

Results are stored under `results/INSTANCE__ioTHREADS.log`.

### Extending test suites
Edit `ansible/roles/memtier/files/test_suites.txt` to add new suite
entries following the `name:=` and `test_commands:=` pattern.
