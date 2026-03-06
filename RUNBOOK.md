# Runbook

Manual setup steps that `setup.sh` cannot automate.

## Before running setup.sh

### Fresh macOS install (optional)

1. Boot into Recovery (hold power on Apple Silicon, Cmd+R on Intel)
2. Erase "Macintosh HD" and reinstall macOS
3. Create primary user account during setup

### FileVault

Enable full-disk encryption before anything else:

**System Settings > Privacy & Security > FileVault > Turn On**

Verify: `fdesetup status`

### System Integrity Protection (SIP)

SIP should be **enabled** (the default). The script checks this but cannot change it.

To verify: `csrutil status`

To change (requires Recovery OS boot):
- Boot into Recovery
- Open Terminal from Utilities menu
- `csrutil enable` or `csrutil disable`

> Disabling SIP is only needed for deep homecall blocking (setup.sh option 5).

## After running setup.sh

### Copy folders from previous machine

Copy these from a backup or previous machine:

```bash
cp -r /Volumes/Backup/.ssh ~/.ssh
chmod 700 ~/.ssh && chmod 600 ~/.ssh/*

cp -r "/Volumes/Backup/Documents/Obsidian Vault" ~/Documents/
```

### SSH keys

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Add the public key to GitHub: <https://github.com/settings/keys>

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

### Git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

### Battery percentage

Cannot be scripted since Big Sur. Enable manually:

**System Settings > Control Center > Battery > Show Percentage**

### Application logins

These apps are installed by setup.sh but require manual sign-in:

- **1Password / Bitwarden** — vault login
- **Google Chrome / Brave** — sync sign-in
- **Slack** — workspace sign-in
- **Signal / Telegram** — device linking
- **Zoom** — account sign-in
- **Obsidian** — vault setup (open local folder or sync)
- **Synology Drive** — NAS connection
- **ProtonVPN** — account sign-in
- **Viscosity** — VPN profile import
- **Little Snitch** — license activation, rule configuration

### GitHub CLI

```bash
gh auth login
```

### Karabiner-Elements

Open Karabiner-Elements and import or configure key remappings. If you have a saved `karabiner.json`, copy it to `~/.config/karabiner/`.

### Browser extensions

Install manually in each browser:

**Safari:** Bitwarden, uBlock Origin, DuckDuckGo Privacy Essentials, Tab Lister

**Chrome / Brave:** Bitwarden, uBlock Origin, DuckDuckGo Privacy Essentials, OneTab, Dark Reader

**Firefox:** Bitwarden, uBlock Origin, NoScript, Privacy Badger, Firefox Multi-Account Containers

### IDE setup

- **VS Code** — sign in with GitHub to sync settings, or manually install extensions
- **JetBrains Toolbox** — sign in, install desired IDEs (IntelliJ, GoLand, etc.)

### Synology NAS (if applicable)

1. Configure Synology Drive client to connect to NAS
2. Set up Syncthing permissions per [v1/docs/synology.md](v1/docs/synology.md)
3. In NAS Control Panel > Group > sc-syncthing, add R/W permissions for synced folders
4. In each synced Shared Folder > Permissions > System Internal User > sc-syncthing, add R/W

### DNS verification

If sites are incorrectly blocked or hosts changes aren't taking effect:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## Periodic maintenance

### Update Homebrew packages

```bash
brew update && brew upgrade && brew cleanup
```

### Refresh /etc/hosts blocklist

Re-run setup.sh option 2, or manually:

```bash
curl -fsSL https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn/hosts -o /tmp/hosts
sudo cp /etc/hosts /etc/hosts.backup
sudo cp /tmp/hosts /etc/hosts
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
```

### Rebuild Zsh plugins

```bash
antidote bundle < ~/.zshplugins > ~/.zsh_plugins.sh
source ~/.zshrc
```
