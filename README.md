# homelab-jlm

# Homelab: "The Disposable Server"
 
A refurbished mini PC turned into a home server (photos, documents, passwords, ad blocker, portfolio), fully described as code in this repository.
 
**Rule of the game: the server must be wipeable and rebuildable in under one hour from this repository.**
 
> Status: Week 1 (foundations) in progress. Sections are added as each step is completed.
 
## Goals
 
- Solve real needs on recycled hardware with infrastructure described as code.
- Practice Linux server administration, Docker, networking, security, CI/CD and backups.
| Service | Role | Access |
|---|---|---|
| AdGuard Home | Network-wide DNS ad blocker | Local network |
| Immich | Photos and videos | Private, via Tailscale |
| Nextcloud | Documents | Private, via Tailscale |
| Vaultwarden | Password manager (Bitwarden compatible) | Private, via Tailscale (HTTPS) |
| Portfolio | Personal website | Public, via Cloudflare Tunnel |
 
**Security principle:** no port is open on the router. Private services go through Tailscale (VPN); the only public service goes through an outbound Cloudflare Tunnel.
 
## Hardware
 
- Mini PC: HP EliteDesk 800 G5 Desktop Mini, Intel Core i5 (generation 9), 16 GB RAM, `<size>` SSD
- OS: Debian 13 (netinst, minimal install, no desktop environment)
 
## Rebuild guide
 
Follow the sections in order. Each step has a **Check** to prove it worked.
 
### 1. Install Debian
 
- Download the netinst ISO from https://www.debian.org/distrib/netinst and write it to a USB stick.
- During installation, select only **SSH server** and **standard system utilities**.
- Hostname: `<hostname>`, user: `<user>` (a non-root user with sudo).
**Check:** the server boots to a login prompt and `ssh <user>@<server-ip>` works from another machine.
 
### 2. Network
 
- Plug the Ethernet cable into the router (interface `eno1`).
- Create a **DHCP reservation** in the router: server MAC address to a fixed IP (SFR box: *LAN* menu, DHCP section).
- Reboot the server.
```bash
ip -br a      # shows the interface, its IP and state
ip -br link   # shows the MAC address
```
 
**Check:** `eno1` is `UP` and has the reserved IP.
 
### 3. System update and base packages
 
```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y curl git ufw unattended-upgrades vim
```
 
If `sudo` is missing, log in as root (`su -`), then:
 
```bash
apt install -y sudo
usermod -aG sudo <user>
```
 
Log out and back in.
 
### 4. SSH: key-based authentication only
 
On the main PC:
 
```bash
ssh-keygen -t ed25519 -C "homelab"
ssh-copy-id <user>@<server-ip>
```
 
Test the key login **in a second terminal** before going further. Then on the server:
 
```bash
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin no
KbdInteractiveAuthentication no
EOF
sudo sshd -t && sudo systemctl reload ssh
```
 
**Check:**
 
```bash
sudo sshd -T | grep -E 'passwordauthentication|permitrootlogin|kbdinteractiveauthentication'
```
 
Expected: `no` for all three. To confirm passwords are refused:
 
```bash
ssh -o PubkeyAuthentication=no <user>@<server-ip>   # Permission denied (publickey)
```
 
Notes:
 
- Keep the current session open until the new login is verified.
- OpenSSH uses the **first** value it reads for an option, so check the effective config with `sshd -T`.
- Adding another key later: log in with an already authorized key and append the new public key to `~/.ssh/authorized_keys`. Keep a backup key (another PC or phone) in case the main PC fails.
### 5. Firewall (ufw)
 
Allow SSH **before** enabling the firewall, otherwise you lock yourself out.
 
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status verbose
```
 
**Check:** `Status: active`, `Default: deny (incoming), allow (outgoing)`, and `22/tcp ALLOW IN` (IPv4 and IPv6).
 
### 6. Automatic security updates
 
```bash
sudo dpkg-reconfigure -plow unattended-upgrades   # answer "Yes"
systemctl status unattended-upgrades
```
 
**Check:** the service is `active`.
 
### 7. Docker Engine and Compose
 
Method: official Docker `apt` repository (https://docs.docker.com/engine/install/debian/, section "Install using the apt repository").
 
```bash
# Paste here the exact commands used from the official page
# (add GPG key, add repository, then:)
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```
 
Log out and back in.
 
**Check:**
 
```bash
docker run hello-world
docker compose version
```
 
Note: membership of the `docker` group is equivalent to root access on the machine.
 
## Rules
 
- **No secrets in Git** (passwords, tokens, keys): everything goes in `.env`, listed in `.gitignore`.
- **No open port** on the router.
- **Pinned Docker image versions** (never `latest`); read release notes before upgrading Immich.
- **Nextcloud and Vaultwarden are never public**: Tailscale only, never behind the Cloudflare Tunnel.
- **Vaultwarden:** sign-ups disabled after creating my account, long master passphrase, two-factor authentication.
- **Photos never go to GitHub:** this repository holds configuration only.
- **An untested backup does not exist.**
## Lessons learned and pitfalls
 
- Interface `DOWN` with `NO-CARRIER`: the Ethernet cable is not detected (check cable, port, router).
- After a reboot the IP may change unless a DHCP reservation exists. The SSH key is not tied to the IP.
- Docker bypasses ufw for published ports: publish private services on `127.0.0.1` or reach them through Tailscale.
## Roadmap
 
- [x] Week 1: Debian, SSH keys, ufw, Docker
- [x] Week 1: automatic security updates verified
- [ ] Week 2: AdGuard Home, Immich, Tailscale, `.env` handling
- [ ] Week 3: portfolio, Cloudflare Tunnel, CI/CD, Vaultwarden
- [ ] Week 4: Nextcloud (or Syncthing), backups, restore test, destruction test
## Destruction test
 
*To be completed: date, real time taken, what failed, what was fixed.*
 