#!/usr/bin/env python3
"""Automate Valkey vs memtier benchmarks on AWS."""
import argparse
import itertools
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INFRA = ROOT / "infrastructure"
ANSIBLE_DIR = ROOT / "ansible"
DRIVER = ROOT / "scripts" / "driver.sh"
RESULTS = ROOT / "results"
RESULTS.mkdir(exist_ok=True)


def run_cmd(cmd, cwd=None, capture=False):
    if capture:
        return subprocess.check_output(cmd, cwd=cwd, text=True)
    subprocess.check_call(cmd, cwd=cwd)


def terraform_apply(tfvars_path):
    run_cmd(["terraform", "init", "-input=false"], cwd=INFRA)
    run_cmd(["terraform", "apply", "-auto-approve", f"-var-file={tfvars_path}"], cwd=INFRA)
    output = run_cmd(["terraform", "output", "-json"], cwd=INFRA, capture=True)
    return json.loads(output)


def terraform_destroy(tfvars_path):
    try:
        run_cmd(["terraform", "destroy", "-auto-approve", f"-var-file={tfvars_path}"], cwd=INFRA)
    except subprocess.CalledProcessError:
        pass


def write_inventory(server_ip, client_ip):
    data = f"""all:\n  hosts:\n    server:\n      ansible_host: {server_ip}\n    client:\n      ansible_host: {client_ip}\n"""
    inv_path = ANSIBLE_DIR / "inventory.yml"
    inv_path.write_text(data)


def run_ansible(io_threads):
    run_cmd([
        "ansible-playbook",
        str(ANSIBLE_DIR / "playbook.yml"),
        "-i",
        str(ANSIBLE_DIR / "inventory.yml"),
        "--extra-vars",
        f"io_threads={io_threads}"
    ])


def run_driver(client_ip, method="score", suite="all", log_path=None):
    env = os.environ.copy()
    env["CLIENT_HOST"] = client_ip
    cmd = [str(DRIVER), method, suite]
    with subprocess.Popen(cmd, env=env, stdout=subprocess.PIPE, text=True) as proc:
        out, _ = proc.communicate()
        if log_path:
            Path(log_path).write_text(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--server", required=True, help="EC2 instance type for server")
    parser.add_argument("--client", required=True, help="EC2 instance type for client")
    parser.add_argument("--io-threads", default="1", help="Number of io threads")
    parser.add_argument("--key", required=True, help="Path to SSH public key")
    parser.add_argument("--vpc", required=True, help="VPC ID")
    parser.add_argument("--subnet", required=True, help="Subnet ID")
    parser.add_argument("--region", required=True, help="AWS region")
    parser.add_argument("--method", default="score", help="Benchmark method")
    parser.add_argument("--suite", default="all", help="Benchmark suite")
    args = parser.parse_args()

    threads = args.io_threads
    with tempfile.NamedTemporaryFile("w", delete=False) as tf:
        tf.write(f"aws_region=\"{args.region}\"\n")
        tf.write(f"public_key_path=\"{args.key}\"\n")
        tf.write(f"server_type=\"{args.server}\"\n")
        tf.write(f"client_type=\"{args.client}\"\n")
        tf.write(f"vpc_id=\"{args.vpc}\"\n")
        tf.write(f"subnet_id=\"{args.subnet}\"\n")
        tf_path = tf.name

    try:
        outputs = terraform_apply(tf_path)
        server_ip = outputs["server_public_ip"]["value"]
        client_ip = outputs["client_public_ip"]["value"]
        write_inventory(server_ip, client_ip)
        run_ansible(threads)
        log_file = RESULTS / f"{args.server}__io{threads}.log"
        run_driver(client_ip, args.method, args.suite, log_file)
    finally:
        terraform_destroy(tf_path)
        os.unlink(tf_path)


if __name__ == "__main__":
    main()
