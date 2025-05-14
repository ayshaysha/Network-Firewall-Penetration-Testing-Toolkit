#!/bin/bash

# Directory setup
mkdir -p scans logs

echo "[+] Starting Reconnaissance Tests..."

# Target from user
TARGET=$1
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <target_ip_or_domain>"
  exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGFILE="logs/recon_$TIMESTAMP.log"
SCANOUT="scans/recon_$TIMESTAMP.json"

###################################
# 1. Basic TCP/UDP Port Scan
###################################
echo "[+] Running TCP/UDP Port Scan..."
nmap -sS -sU -T4 -Pn -p- --min-rate 1000 -oX scans/nmap_tcpudp_$TIMESTAMP.xml $TARGET | tee -a $LOGFILE

###################################
# 2. OS & Service Fingerprinting
###################################
echo "[+] Detecting OS and Services..."
nmap -O -sV -T4 -Pn --version-all --osscan-guess -oX scans/nmap_osfinger_$TIMESTAMP.xml $TARGET | tee -a $LOGFILE

###################################
# 3. Firewall Detection with Nmap
###################################
echo "[+] Performing firewall detection..."
nmap -sA -T4 -Pn -oX scans/nmap_firewall_$TIMESTAMP.xml $TARGET | tee -a $LOGFILE

###################################
# 4. TTL Based Fingerprinting (Nmap)
###################################
echo "[+] Running TTL-based fingerprinting..."
nmap -sP -v --traceroute $TARGET | tee -a $LOGFILE

###################################
# 5. Passive Fingerprinting (p0f)
###################################
echo "[+] Launching passive fingerprinting with p0f..."
p0f -i eth0 -o scans/p0f_$TIMESTAMP.log -s $TARGET &
echo "Let it run for 30 seconds..."
sleep 30
killall p0f

###################################
# 6. Traceroute to detect NAT/firewall hops
###################################
echo "[+] Running traceroute..."
traceroute $TARGET | tee -a $LOGFILE

###################################
# 7. Stateful Firewall Check (SYN/ACK)
###################################
echo "[+] Checking for stateful firewall behavior..."
hping3 -S -p 80 -c 3 $TARGET > scans/hping_stateful_$TIMESTAMP.log
hping3 -A -p 80 -c 3 $TARGET >> scans/hping_stateful_$TIMESTAMP.log

###################################
# 8. Rate Limiting / Flood Resilience
###################################
echo "[+] Checking for rate limiting with SYN flood..."
hping3 -S -p 80 --flood $TARGET --rand-source -c 1000 > scans/hping_dos_$TIMESTAMP.log

###################################
# 9. NAT Detection via TTL/ID analysis
###################################
echo "[+] Checking for NAT presence (TTL/IP-ID)..."
nmap -T4 -Pn -p 80 --reason --packet-trace $TARGET | tee -a $LOGFILE

###################################
# 10. DNS Tunneling Test (iodine)
###################################
echo "[+] Checking for DNS Tunneling with iodine..."
if command -v iodine >/dev/null 2>&1; then
  iodine -f -P testpassword tunnel.yourdomain.com > scans/iodine_$TIMESTAMP.log 2>&1 &
  sleep 20
  killall iodine
else
  echo "[-] iodine not installed, skipping..." | tee -a $LOGFILE
fi

###################################
# 11. DNS Tunneling Test (dns2tcp)
###################################
echo "[+] Checking for DNS Tunneling with dns2tcp..."
if command -v dns2tcp >/dev/null 2>&1; then
  dns2tcpd -f -F scans/dns2tcp_$TIMESTAMP.log -r tunnel.yourdomain.com -u 5353 &
  sleep 20
  killall dns2tcpd
else
  echo "[-] dns2tcp not installed, skipping..." | tee -a $LOGFILE
fi

# Consolidate to JSON log format for later reporting
python3 scripts/consolidate_recon.py scans/ logs/ $TIMESTAMP

echo "[+] Reconnaissance complete. Logs saved to $LOGFILE"
echo "[+] Next: Tunneling tests"
