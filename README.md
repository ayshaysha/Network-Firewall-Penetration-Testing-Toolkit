# 🔥 Network-Firewall-Penetration-Testing-Toolkit

A fully automated, black-box network firewall testing tool built for Kali Linux. Tests filtering, evasion, tunneling, reverse shells, and CVE exposure. Generates professional PDF reports.

## 🧰 Features

- Recon & evasion (Nmap, hping3, traceroute)
- DNS tunneling tests (iodine, dns2tcp)
- Reverse shell bypass with Metasploit + ProxyChains
- CVE-linked PDF reports
- Makefile for one-command automation

## 📦 Requirements

- Kali Linux (or equivalent)
- Python 3 (`pip install fpdf`)
- Metasploit Framework
- ProxyChains, curl, iodine, dns2tcp

## 🚀 Usage

```bash
# One-line run (uses Makefile)
make TARGET=<target_ip>

# Or manual steps
./firewall_recon.sh <target_ip>
./reverse_shell_test.sh <your_kali_ip> <target_ip> <target_open_port>
python3 scripts/update_cve_map.py
python3 scripts/generate_report.py logs/latest.log scans/ reports/
