# Andrew's .files

The Ansible-based provisioning system in `v1/` is **unmaintained as of macOS 14 (Sonoma)**. It may still work for reference but is no longer tested or updated.

## Setup (v2)

A single interactive script that installs Homebrew packages, configures `/etc/hosts` ad-blocking, hardens macOS security settings, and applies UX preferences.

```bash
curl -s https://raw.githubusercontent.com/adrw/.files/master/setup.sh -o setup.sh && bash setup.sh
```

Or clone and run directly:

```bash
git clone https://github.com/adrw/.files.git ~/.files && cd ~/.files && bash setup.sh
```

### What it does

Run `setup.sh` and select from the menu:

1. **Homebrew packages** — grouped by category (core CLI, dev, productivity, tools, media, fonts, backup)
2. **/etc/hosts blocking** — Steven Black's ad/tracker/gambling/porn/social blocklist
3. **macOS security hardening** — firewall, hostname, privacy defaults (based on [drduh/macOS-Security-and-Privacy-Guide](https://github.com/drduh/macOS-Security-and-Privacy-Guide))
4. **macOS UX preferences** — trackpad, screenshots, Finder, hot corners
5. **Homecall blocking** — disable macOS daemons/agents that phone home

### Previous version

See [`v1/`](v1/) for the original Ansible-based system and its [README](v1/README.md).
