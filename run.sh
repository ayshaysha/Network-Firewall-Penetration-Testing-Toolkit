#!/bin/bash

TARGET=$1

if [ -z "$TARGET" ]; then
  echo "Usage: ./run.sh <target_ip_or_domain>"
  exit 1
fi

echo "=========================================="
echo "🚀 FPTT: Firewall Penetration Testing Tool"
echo "=========================================="
echo "[*] Target: $TARGET"
echo "[*] Starting full scan sequence..."

# Run all tests
chmod +x firewall_recon.sh
./firewall_recon.sh "$TARGET"

# Final report generation
echo "[*] Generating PDF report..."
python3 scripts/generate_report.py "logs/recon_"*"$TARGET"*.log "scans" "reports"

echo "[✅] Done. Check the reports/ directory for your output."
