# Makefile for Firewall Penetration Testing Toolkit

TARGET=127.0.0.1
SCAN_DIR=scans
LOG_FILE=logs/latest.log
REPORT_DIR=reports

all: test update_cves report

# Run the main testing suite
test:
	@echo "[+] Running firewall recon tests against $(TARGET)..."
	chmod +x firewall_recon.sh
	./firewall_recon.sh $(TARGET) > $(LOG_FILE)

# Refresh the CVE database
update_cves:
	@echo "[+] Updating CVE references..."
	python3 update_cve_map.py

# Generate the PDF report
report:
	@echo "[+] Generating PDF report..."
	python3 scripts/generate_report.py $(LOG_FILE) $(SCAN_DIR) $(REPORT_DIR)

clean:
	rm -rf scans/* logs/* reports/* cve_map.json
	@echo "[+] Cleaned all outputs."

.PHONY: all test update_cves report clean
