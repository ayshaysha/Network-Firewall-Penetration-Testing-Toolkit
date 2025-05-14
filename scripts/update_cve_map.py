import requests
import json

CVE_TOPICS = {
    "nmap_tcpudp": "port scanning",
    "nmap_firewall": "firewall bypass",
    "hping_dos": "SYN flood",
    "iodine": "dns tunneling",
    "dns2tcp": "dns tunneling",
    "hping_stateful": "stateful firewall",
    "nmap_osfinger": "os fingerprinting"
}

NVD_API = "https://services.nvd.nist.gov/rest/json/cves/2.0"

HEADERS = {
    "User-Agent": "FirewallToolkit/1.0"
}

MAX_PER_QUERY = 3

out = {}

def fetch_cves(keyword):
    params = {
        "keywordSearch": keyword,
        "resultsPerPage": MAX_PER_QUERY
    }
    try:
        r = requests.get(NVD_API, params=params, headers=HEADERS)
        r.raise_for_status()
        results = r.json().get("vulnerabilities", [])
        cves = []
        for entry in results:
            cve = entry["cve"]
            cves.append({
                "id": cve["id"],
                "desc": cve["descriptions"][0]["value"],
                "link": f"https://nvd.nist.gov/vuln/detail/{cve['id']}"
            })
        return cves
    except Exception as e:
        print(f"[!] Failed to fetch CVEs for '{keyword}': {e}")
        return []

def update_map():
    for key, keyword in CVE_TOPICS.items():
        print(f"[*] Fetching CVEs for: {keyword}")
        out[key] = fetch_cves(keyword)

    with open("cve_map.json", "w") as f:
        json.dump(out, f, indent=2)
    print("[+] CVE map saved to cve_map.json")

if __name__ == "__main__":
    update_map()
