
---

## ✨ Why VISIBLE TECH MANAGER?

Visible tech Manager is built with an **obsessive focus on speed, fluidity, and aesthetics**. We took the traditional chunky script and refined it into a gorgeous, highly responsive, and relentlessly efficient terminal experience.

Whether you're managing 5 users or 500, deploying complex protocols, or locking down your server traffic—you can do it all in seconds, with zero frustration.

---

## 🚀 Installation

It takes less than a minute to deploy the complete visible tech Manager on your fresh VPS. Choose the installation method that works best for you:



### MANAGER INSTALLATION💡
```bash

# on the server🚦

sudo rm -f /etc/resolv.conf && \
sudo tee /etc/resolv.conf >/dev/null <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 9.9.9.9
EOF
apt update && \
apt install -y curl && \
curl -L -o install.sh "https://raw.githubusercontent.com/wavy07/manage/main/install.sh" && chmod +x install.sh && sudo ./install.sh && rm install.sh
```

*(Once installed, simply type `menu` in your terminal to launch the interface!)*

---

## 🌟 Elite Features

### 👤 Hyper-Optimized User Management
* **Batch Operations Engine:** Delete, Lock, Unlock, or Renew multiple users simultaneously. You can type `1 3 5` or ranges like `1-4` to execute massive operations in the blink of an eye.
* **Smart UI Selection:** Automatically detects your user count. If you have fewer than 15 active users, it dynamically skips the search prompt to save you keystrokes.
* **Agile Creation:** Bulk string generation with instant preset defaults (`Enter` for 30 Days, unlimited Bandwidth, 1 Device Connection).
* **Temporary Trial Accounts:** Instantly spin up self-destructing trial accounts spanning 1, 2, 6, 12, or 24 hours (powered autonomously by the `at` daemon).

### 🛠️ One-Click VPN & Protocol Deployers
Easily spin up entire tunneling infrastructures onto your server without touching a single complex config file.
* **BadVPN (UDP Gateway):** Optimize gaming and tunneling packets.
* **UDP Custom:** Manage customizable UDP bypasses.
* **SSL Tunnels:** HAProxy payload routing on port 444.
* **Nginx Reverse Proxy:** Full HTTP/HTTPS webserver installer, featuring **Auto-Certbot integration** for free SSL certificates.
* **DNSTT (SlowDNS):** Bypass heavy firewalls through port 53 DNS records.
* **Falcon Proxy:** Setup and customize version-controlled Websocket/Socks proxies.
* **ZiVPN (UDP):** Accelerated custom UDP handling.
* **X-UI Web Panel:** Automated installer for the infamous GUI management portal.

### 📊 Advanced Quotas & Network Safety
* **Strict Bandwidth Limiting:** Assign gigabyte allowances (e.g., 50GB) upon creation. Background services will safely and automatically lock users who exceed their usage.
* **Active Connection Limits:** Ensure nobody shares their account by enforcing strict concurrent session limits. 
* **Live Traffic Monitor:** Check high-speed Bash network tracking (or install `vnstat` for persistent metrics).
* **Anti-Torrent Guard:** Deploy stateful iptables payload inspection to permanently drop `BitTorrent` data, protecting your host from abuse complaints.

### 🎨 Beautiful SSH Customization
* **Dynamic Login Banners:** visibletech-manager overrides the default SSH `sshd_config` to inject an intelligent script. 
* When your users connect via an HTTP injector or SSH tunnel app, they are greeted by a beautiful customized text box detailing their exact:
  * Expiry Date
  * Quota Remaining
  * Real-Time Active Connections

### 💾 Backup & Restore Stability
* Automatically collect your payload records, user databases, TLS certificates, and bandwidth usage statistics into single portable `.tar.gz` archives. Restore entire businesses onto a new server with one menu click.



<div align="center">
  <b>Built by visible tech  FOUNDER~.inc🦜</b><br>
  <i>"Fast configuration, Secure tunneling, Beautiful interfaces."</i>
</div>
