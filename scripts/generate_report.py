import os
import sys
import json
from fpdf import FPDF
from datetime import datetime

class Report(FPDF):
    def header(self):
        self.set_font('Arial', 'B', 12)
        self.cell(0, 10, 'Firewall Penetration Testing Report', ln=True, align='C')
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')

    def section_title(self, title):
        self.set_font('Arial', 'B', 11)
        self.set_text_color(40, 40, 40)
        self.cell(0, 10, title, ln=True)
        self.set_text_color(0, 0, 0)

    def section_body(self, content):
        self.set_font('Arial', '', 10)
        self.multi_cell(0, 8, content)
        self.ln()

    def section_table(self, headers, rows):
        self.set_font('Arial', 'B', 10)
        col_widths = [40, 40, 30, 80]
        for i, header in enumerate(headers):
            self.cell(col_widths[i], 8, header, 1)
        self.ln()

        self.set_font('Arial', '', 9)
        for row in rows:
            for i, item in enumerate(row):
                self.cell(col_widths[i], 8, item, 1)
            self.ln()

def load_cve_map():
    try:
        with open('cve_map.json', 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"[!] Failed to load CVE map: {e}")
        return {}

def generate_risk_table(scan_dir, cve_map):
    tests = {
        "nmap_tcpudp": "Port Filtering",
        "nmap_osfinger": "OS Fingerprinting",
        "nmap_firewall": "Firewall Detection",
        "hping_stateful": "Stateful Check",
        "hping_dos": "DoS Protection",
        "iodine": "DNS Tunneling",
        "dns2tcp": "DNS Tunneling"
    }

    rows = []
    for file in os.listdir(scan_dir):
        for key, name in tests.items():
            if key in file:
                status = "Detected" if os.path.getsize(os.path.join(scan_dir, file)) > 0 else "Not Detected"
                risk = "High" if "tunnel" in key or "dos" in key else "Medium" if "tcpudp" in key else "Low"
                cves = ", ".join([entry['id'] for entry in cve_map.get(key, [])]) if key in cve_map else "None"
                rows.append([name, status, risk, cves])
    return rows

def extract_log_summary(scan_dir):
    summary = ""
    for file in sorted(os.listdir(scan_dir)):
        path = os.path.join(scan_dir, file)
        if file.endswith('.log') or file.endswith('.xml'):
            summary += f"\n--- {file} ---\n"
            try:
                with open(path, 'r', errors='ignore') as f:
                    lines = f.readlines()
                    summary += ''.join(lines[:20]) + '\n...\n\n'
            except Exception as e:
                summary += f"[Error reading file: {e}]\n\n"
    return summary

def main(logfile_path, scan_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    pdf_path = os.path.join(output_dir, f"report_{timestamp}.pdf")

    cve_map = load_cve_map()

    pdf = Report()
    pdf.add_page()

    pdf.section_title("1. Executive Summary")
    pdf.section_body("This report summarizes the results of an automated firewall penetration test. It includes reconnaissance, evasion, and tunneling evaluations to assess firewall robustness and misconfigurations.")

    pdf.section_title("2. Risk Scoring & CVE References")
    table = generate_risk_table(scan_dir, cve_map)
    pdf.section_table(["Module", "Status", "Risk Level", "CVEs Linked"], table)

    pdf.section_title("3. Scan Summary")
    summary = extract_log_summary(scan_dir)
    pdf.section_body(summary)

    pdf.section_title("4. Recommendations")
    pdf.section_body("Review open ports, apply strict outbound rules, restrict DNS/ICMP tunneling, and monitor rate limiting. Consider enforcing deep packet inspection and protocol validation.\n\nRefer to related MITRE ATT&CK techniques:")
    pdf.section_body("- T1071: Application Layer Protocol\n- T1095: Non-Application Layer Protocol")

    pdf.output(pdf_path)
    print(f"[+] Report generated at: {pdf_path}")

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print("Usage: python3 generate_report.py <log_file_path> <scan_dir> <output_dir>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3])
