#!/usr/bin/env bash
# macOS setup script — interactive, menu-driven
# Source: https://github.com/adrw/.files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[SKIP]${NC} $*"; }
err()     { echo -e "${RED}[ERR]${NC} $*"; }
section() { echo -e "\n${BOLD}${BLUE}==> $*${NC}"; }

# ---------------------------------------------------------------------------
# Homebrew package groups
# ---------------------------------------------------------------------------

BREW_CORE=(
  act
  bat
  # certbot          # DEPRECATED? — rarely needed on personal machines, more for servers
  # cheat            # DEPRECATED? — community cheatsheets; tldr is similar and more maintained
  # coreutils
  # exiftool
  # figlet
  git-quick-stats
  gh
  # hub              # DEPRECATED — gh (GitHub CLI) has replaced hub's functionality
  htop
  # jhead
  # jo               # DEPRECATED? — jq alone covers most JSON needs
  jq
  # neofetch         # DEPRECATED — archived by author in 2024, consider fastfetch
  # node
  # openssl
  # pngquant
  # pyenv
  # python3          # `python` and `python3` are the same formula now
  ripgrep
  shellcheck
  # speedtest-cli    # DEPRECATED? — Ookla now has an official `speedtest` brew package
  tldr
  # travis           # DEPRECATED — Travis CI has declined significantly since 2020
  tree
  wget
  # yarn             # DEPRECATED? — modern Node ships with corepack/pnpm, yarn classic is legacy
)

CASK_DEVELOPMENT=(
  copilot-cli
  docker-desktop
  ghostty
  # insomnia         # DEPRECATED? — acquired by Kong, many users migrated to Bruno or Hoppscotch
  jetbrains-toolbox
  # ngrok
  # postico
  visual-studio-code
)

CASK_PRODUCTIVITY=(
  # barrier          # DEPRECATED? — project has had minimal maintenance since 2022, consider input-leap (the active fork)
  # basecamp         # DEPRECATED? — Basecamp no longer ships a native Mac app, web-only now
  brave-browser
  google-chrome
  obsidian
  signal
  slack
  telegram
  zoom
)

CASK_TOOLS=(
  1password
  # alfred
  appcleaner
  bisq
  bitwarden
  bitwarden-cli
  caffeine
  # charles
  conductor
  karabiner-elements
  keymapp
  little-snitch
  meetingbar
  # monitorcontrol
  protonvpn
  raycast
  rectangle
  superwhisper
  thaw
  the-unarchiver
  utm
  utc-menu-clock
  viscosity
  xbar
)

CASK_MEDIA=(
  calibre
  # imagealpha       # DEPRECATED? — pngquant CLI does the same thing, imagealpha is just a GUI wrapper
  openaudible
  mediahuman-audio-converter
  musicbrainz-picard
  # spotify
  transmission
  vlc
)

CASK_FONTS=(
  font-fira-code
  # font-fira-mono-for-powerline  # DEPRECATED? — Nerd Fonts patches are more common now
  font-fontawesome
  font-jetbrains-mono
  font-poppins
  # font-poppins-latin             # DEPRECATED? — font-poppins already includes latin glyphs
  font-sans-forgetica
)

CASK_BACKUP=(
  synology-drive
  synology-surveillance-station-client
)

BREW_HIGHBEAM=(
  # Add Highbeam-specific homebrew packages here, e.g.:
  # awscli
  # terraform
  google-cloud-sdk
  hashicorp/tap/terraform
  kubectl
  pgcli
)

# ---------------------------------------------------------------------------
# /etc/hosts blocklist URLs (Steven Black)
# ---------------------------------------------------------------------------
HOSTS_BASE_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn/hosts"
HOSTS_SOCIAL_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-social/hosts"

CUSTOM_FACEBOOK_HOSTS="# Facebook (custom — blocks main site, allows messenger.com)
0.0.0.0 facebook.com
0.0.0.0 m.facebook.com
0.0.0.0 www.facebook.com"

# ---------------------------------------------------------------------------
# Homecall daemons/agents to disable
# ---------------------------------------------------------------------------
HOMECALL_DAEMONS=(
  com.apple.netbiosd
  com.apple.familycontrols
  com.apple.SubmitDiagInfo
  com.apple.screensharing
  com.apple.appleseed.fbahelperd
  com.apple.awacsd
  com.apple.awdd
  com.apple.CrashReporterSupportHelper
)

HOMECALL_AGENTS=(
  com.apple.gamed
  com.apple.cloudfamilyrestrictionsd-mac
  com.apple.cloudpaird
  com.apple.cloudphotosd
  com.apple.DictationIM
  com.apple.assistant_service
  com.apple.appleseed.seedusaged
  com.apple.parentalcontrols.check
  com.apple.parsecd
  com.apple.rtcreportingd
  com.apple.SafariCloudHistoryPushAgent
  com.apple.safaridavclient
  com.apple.SafariNotificationAgent
)

# ===========================================================================
# Functions
# ===========================================================================

confirm() {
  local prompt="${1:-Continue?}"
  read -r -p "${prompt} [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]]
}

# ensure_block FILE MARKER_ID CONTENT
# Inserts or replaces a marked block in FILE. Idempotent — safe to call
# repeatedly without duplicating content. Content outside the markers is
# preserved.
ensure_block() {
  local file="$1" marker="$2" content="$3"
  local begin="### BEGIN ${marker}"
  local end="### END ${marker}"
  if [[ -f "$file" ]] && grep -qF "$begin" "$file" 2>/dev/null; then
    # Replace existing block (use temp files to avoid awk -v newline issues on macOS)
    local tmp content_file
    tmp="$(mktemp)"
    content_file="$(mktemp)"
    printf '%s\n' "$content" > "$content_file"
    awk -v b="$begin" -v e="$end" -v cf="$content_file" '
      $0 == b  { print b; while ((getline line < cf) > 0) print line; close(cf); skip=1; next }
      $0 == e  { skip=0; print e; next }
      !skip    { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
    rm -f "$content_file"
  elif [[ -f "$file" ]]; then
    # Append new block
    printf '\n%s\n%s\n%s\n' "$begin" "$content" "$end" >> "$file"
  else
    # Create file with block
    printf '%s\n%s\n%s\n' "$begin" "$content" "$end" > "$file"
  fi
}

install_xcode_cli_tools() {
  section "Xcode Command Line Tools"
  if xcode-select -p &>/dev/null; then
    info "Xcode Command Line Tools already installed ($(xcode-select -p))"
  else
    echo "Xcode Command Line Tools are required for git, compilers, and Homebrew."
    echo "A system dialog will appear to guide installation."
    xcode-select --install 2>/dev/null || true
    echo ""
    echo -e "${YELLOW}Waiting for Xcode Command Line Tools installation to complete...${NC}"
    echo "Please follow the system dialog, then press Enter here when done."
    read -r -p "Press Enter to continue after installation finishes..."
    if xcode-select -p &>/dev/null; then
      info "Xcode Command Line Tools installed"
    else
      err "Xcode Command Line Tools installation not detected — some steps may fail"
    fi
  fi
}

install_homebrew() {
  if command -v brew &>/dev/null; then
    info "Homebrew already installed"
    return
  fi
  section "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to path for this session
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  info "Homebrew installed"
}

brew_install_list() {
  local label="$1"
  shift
  local -a packages=("$@")
  section "Installing: ${label}"
  for pkg in "${packages[@]}"; do
    # Strip inline comments for display
    local clean="${pkg%%#*}"
    clean="${clean%% *}"
    clean="$(echo "$clean" | xargs)" # trim whitespace
    [[ -z "$clean" ]] && continue
    if brew list --formula "$clean" &>/dev/null 2>&1 || brew list --cask "$clean" &>/dev/null 2>&1; then
      warn "${clean} (already installed)"
    else
      echo -e "  Installing ${BOLD}${clean}${NC}..."
      # Try as formula first, then cask — don't suppress stderr so failures are visible
      if brew install "$clean" 2>&1 || brew install --cask "$clean" 2>&1; then
        info "${clean}"
      else
        err "${clean} — install failed"
      fi
    fi
  done
}

run_homebrew() {
  install_homebrew

  echo ""
  echo -e "${BOLD}Select package groups to install:${NC}"
  echo "  1) Core CLI tools (bat, ripgrep, jq, htop, wget, tree, etc.)"
  echo "  2) Development (Docker, VS Code, JetBrains, ngrok, Postico)"
  echo "  3) Productivity (browsers, Slack, Notion, Signal, Todoist)"
  echo "  4) Tools (Alfred, Bitwarden, Rectangle, MonitorControl, etc.)"
  echo "  5) Media (Spotify, VLC, Calibre, Transmission)"
  echo "  6) Fonts (Fira Code, JetBrains Mono, Font Awesome)"
  echo "  7) Backup (Synology Drive)"
  echo "  a) All of the above"
  echo ""
  read -r -p "Enter choices (e.g. 1,3,4 or a): " choices

  if [[ "$choices" == *"a"* ]]; then
    choices="1,2,3,4,5,6,7"
  fi

  IFS=',' read -ra selected <<< "$choices"
  for choice in "${selected[@]}"; do
    choice="$(echo "$choice" | xargs)"
    case "$choice" in
      1) brew_install_list "Core CLI tools" "${BREW_CORE[@]}" ;;
      2) brew_install_list "Development apps" "${CASK_DEVELOPMENT[@]}" ;;
      3) brew_install_list "Productivity apps" "${CASK_PRODUCTIVITY[@]}" ;;
      4) brew_install_list "Tools" "${CASK_TOOLS[@]}" ;;
      5) brew_install_list "Media apps" "${CASK_MEDIA[@]}" ;;
      6) brew_install_list "Fonts" "${CASK_FONTS[@]}" ;;
      7) brew_install_list "Backup" "${CASK_BACKUP[@]}" ;;
      *) warn "Unknown selection: ${choice}" ;;
    esac
  done
}

run_etchosts() {
  section "/etc/hosts ad-blocking"
  echo "Downloads Steven Black's unified hosts list and installs to /etc/hosts."
  echo "Any custom host entries above '# Start StevenBlack' are preserved."
  echo ""
  echo "Base list always includes: ads, malware, gambling, and porn blocklists."
  echo ""
  echo "Optional add-ons:"
  echo "  s) Social media blocking (Facebook, Twitter, Instagram, TikTok, etc.)"
  echo "     NOTE: LinkedIn is always excluded from social blocking."
  echo "  n) None — base blocklist only"
  echo ""
  read -r -p "Include social media blocking? [s/N] " social_choice

  local use_social=false
  if [[ "$social_choice" =~ ^[Ss]$ ]]; then
    use_social=true
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  local url="$HOSTS_BASE_URL"
  $use_social && url="$HOSTS_SOCIAL_URL"

  local label="ads + gambling + porn"
  $use_social && label="${label} + social"

  echo "Downloading hosts list (${label})..."
  if ! curl -fsSL "$url" -o "$tmpdir/downloaded.hosts"; then
    err "Failed to download hosts list"
    return 1
  fi

  if $use_social; then
    # Strip LinkedIn social block (keep ad tracker entries from base list)
    echo "Stripping LinkedIn from social blocklist..."
    sed '/^# LinkedIn$/,/^# [A-Z]/{
      /^# LinkedIn$/d
      /^# [A-Z]/!d
    }' "$tmpdir/downloaded.hosts" > "$tmpdir/blocklist.hosts"

    # Replace full Facebook block with curated subset (allows Messenger)
    echo "Replacing Facebook block with curated subset..."
    sed -i '' '/^# Facebook$/,/^# Twitter$/{
      /^# Facebook$/d
      /^# Twitter$/!d
    }' "$tmpdir/blocklist.hosts"
    sed -i '' "/^# Twitter$/i\\
\\
${CUSTOM_FACEBOOK_HOSTS}\\
" "$tmpdir/blocklist.hosts"
    label="${label} (minus LinkedIn)"
  else
    cp "$tmpdir/downloaded.hosts" "$tmpdir/blocklist.hosts"
  fi

  # Preserve custom entries above "# Start StevenBlack" from current /etc/hosts,
  # then append the fresh blocklist below.
  if [[ -f /etc/hosts ]] && grep -qn "^# Start StevenBlack" /etc/hosts; then
    local marker_line
    marker_line=$(grep -n "^# Start StevenBlack" /etc/hosts | head -1 | cut -d: -f1)
    head -n "$((marker_line - 1))" /etc/hosts > "$tmpdir/final.hosts"
  else
    # No existing marker — use a minimal default header
    cat > "$tmpdir/final.hosts" << 'HEADER'
127.0.0.1 localhost
127.0.0.1 localhost.localdomain
255.255.255.255 broadcasthost
::1 localhost

# Custom host records are listed here.

# End of custom host records.
HEADER
  fi

  # Append the blocklist (which already starts with "# Start StevenBlack")
  cat "$tmpdir/blocklist.hosts" >> "$tmpdir/final.hosts"

  # Backup existing hosts file
  if [[ -f /etc/hosts ]]; then
    sudo cp /etc/hosts "/etc/hosts.backup.$(date +%Y%m%d%H%M%S)"
    info "Backed up /etc/hosts"
  fi

  sudo cp "$tmpdir/final.hosts" /etc/hosts

  # Flush DNS cache
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder 2>/dev/null || true

  info "/etc/hosts installed: ${label} ($(wc -l < /etc/hosts | xargs) lines)"
}

run_security() {
  section "macOS Security Hardening"
  echo "Based on drduh/macOS-Security-and-Privacy-Guide and existing .files config."
  echo ""
  echo "This will:"
  echo "  - Enable firewall + stealth mode"
  echo "  - Disable firewall auto-whitelist for signed apps"
  echo "  - Set hostname to a generic name"
  echo "  - Require password immediately on sleep/screensaver"
  echo "  - Show all file extensions"
  echo "  - Disable iCloud as default save location"
  echo "  - Disable crash reporter dialog"
  echo "  - Show hidden files and ~/Library in Finder"
  echo "  - Disable Spotlight/Siri suggestions and web search"
  echo "  - Disable Captive Portal assistant"
  echo ""
  if ! confirm "Apply security hardening?"; then
    warn "Skipped security hardening"
    return
  fi

  sudo -v
  # Keep sudo alive in background
  while true; do sudo -n true; sleep 60; kill -0 "$$" || break; done 2>/dev/null &
  local sudo_pid=$!

  # --- Firewall ---
  section "Firewall"
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off
  sudo pkill -HUP socketfilterfw 2>/dev/null || true
  info "Firewall enabled with stealth mode, auto-whitelist off"

  # --- Hostname ---
  section "Hostname"
  local current_hostname
  current_hostname="$(hostname)"
  read -r -p "Set hostname (current: ${current_hostname}) [Enter to use 'MacBook']: " new_hostname
  new_hostname="${new_hostname:-MacBook}"
  sudo scutil --set ComputerName "$new_hostname"
  sudo scutil --set HostName "$new_hostname"
  sudo scutil --set LocalHostName "$new_hostname"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$new_hostname"
  info "Hostname set to: ${new_hostname}"

  # --- Screen lock ---
  section "Screen Lock"
  # defaults write com.apple.screensaver askForPassword is unreliable on Sonoma+.
  # sysadminctl -screenLock is the modern replacement.
  if sysadminctl -screenLock immediate 2>/dev/null; then
    info "Screen lock set to require password immediately"
  else
    # Fallback for older macOS
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    info "Screen lock set (legacy method)"
  fi

  # --- Finder privacy ---
  section "Finder & File Privacy"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  chflags nohidden ~/Library
  info "Show all extensions, hidden files, and ~/Library"

  # --- iCloud ---
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
  info "New documents save locally by default"

  # --- Crash reporter ---
  defaults write com.apple.CrashReporter DialogType none
  info "Crash reporter dialog disabled"

  # --- Captive Portal ---
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false
  info "Captive Portal assistant disabled"

  # --- Spotlight/Siri ---
  section "Spotlight & Siri Privacy"
  defaults write com.apple.Safari UniversalSearchEnabled -bool NO 2>/dev/null || true
  defaults write com.apple.Safari SuppressSearchSuggestions -bool YES 2>/dev/null || true
  defaults write com.apple.Safari WebsiteSpecificSearchEnabled -bool NO 2>/dev/null || true
  info "Safari search suggestions and web search disabled"
  echo "  (For deeper Spotlight/Siri suggestions blocking, also run section 5: Homecall blocking)"

  # --- SIP check ---
  section "System Integrity Protection"
  if csrutil status 2>/dev/null | grep -q "enabled"; then
    info "SIP is enabled"
  else
    err "SIP is NOT enabled — reboot into Recovery OS and run 'csrutil enable'"
  fi

  # --- FileVault check ---
  if fdesetup status 2>/dev/null | grep -q "On"; then
    info "FileVault is enabled"
  else
    err "FileVault is NOT enabled — enable in System Settings > Privacy & Security > FileVault"
  fi

  kill "$sudo_pid" 2>/dev/null || true
  info "Security hardening complete"
}

run_macos_prefs() {
  section "macOS UX Preferences"
  echo "This will configure trackpad, screenshots, hot corners, and locale."
  echo ""
  if ! confirm "Apply macOS UX preferences?"; then
    warn "Skipped macOS preferences"
    return
  fi

  # Close System Preferences/Settings to prevent conflicts
  osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
  osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

  sudo -v

  # --- Trackpad ---
  section "Trackpad"
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
  defaults write -g com.apple.mouse.scaling 4.5
  defaults write -g com.apple.trackpad.scaling 4.5
  # NOTE: ActuationStrength (silent click) is broken on Sonoma 14.4+ and Apple Silicon Macs.
  # Removed — no longer scriptable.
  info "3-finger drag enabled, tracking speed increased"

  # --- Menu bar ---
  # NOTE: Battery percentage can no longer be set via defaults write (broken since Big Sur).
  # Must be set manually: System Settings > Control Center > Battery > Show Percentage.
  warn "Battery percentage must be enabled manually: System Settings > Control Center > Battery > Show Percentage"

  # --- Sidebar ---
  defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1
  info "Sidebar icon size: small"

  # --- Screenshots ---
  mkdir -p "${HOME}/Pictures/Screenshots"
  defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
  info "Screenshots save to ~/Pictures/Screenshots"

  # --- Finder ---
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
  info "New Finder windows open to home directory"

  # --- Locale ---
  defaults write NSGlobalDomain AppleLanguages -array "en"
  defaults write NSGlobalDomain AppleLocale -string "en_CA@currency=CAD"
  defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
  defaults write NSGlobalDomain AppleMetricUnits -bool true
  sudo systemsetup -settimezone "America/Toronto" > /dev/null 2>&1 || true
  info "Locale: en_CA, timezone: America/Toronto"

  # --- Appearance ---
  # Dark mode
  defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
  info "Dark mode enabled"

  # --- Accessibility ---
  defaults write com.apple.universalaccess increaseContrast -bool true
  defaults write com.apple.universalaccess differentiateWithoutColor -bool true
  defaults write com.apple.universalaccess reduceTransparency -bool true
  info "Accessibility: Increase Contrast, Differentiate without Color, and Reduce Transparency enabled"

  # --- Dock ---
  defaults write com.apple.dock persistent-apps -array
  defaults write com.apple.dock persistent-others -array
  defaults write com.apple.dock recent-apps -array
  defaults write com.apple.dock autohide -bool true
  killall Dock 2>/dev/null || true
  info "Dock: removed all existing items, auto-hide enabled"

  # --- Hot corners ---
  # Top left → Put display to sleep
  defaults write com.apple.dock wvous-tl-corner -int 10
  defaults write com.apple.dock wvous-tl-modifier -int 1
  info "Hot corner: top-left → display sleep"

  # --- Transmission ---
  mkdir -p "${HOME}/Downloads/Torrents/Downloading"
  defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
  defaults write org.m0k.transmission IncompleteDownloadFolder -string "${HOME}/Downloads/Torrents"
  defaults write org.m0k.transmission DownloadLocationConstant -bool true
  defaults write org.m0k.transmission CompleteDownloadFolder -string "${HOME}/Downloads/Torrents"
  info "Transmission: downloads to ~/Downloads/Torrents"

  info "macOS preferences applied — some changes require logout/restart"
}

run_homecall() {
  section "Homecall Blocking"
  echo "Disables macOS daemons and agents that phone home to Apple."
  echo "Based on https://github.com/karek314/macOS-home-call-drop"
  echo ""

  local sip_enabled=false
  if csrutil status 2>/dev/null | grep -q "enabled"; then
    sip_enabled=true
    warn "SIP is enabled — daemons/agents under /System/Library/ CANNOT be disabled."
    echo "  All targets in this section are under /System/Library/ and require SIP off."
    echo "  To disable SIP: reboot into Recovery OS (Cmd+R) and run 'csrutil disable'."
    echo ""
    echo "  The Spotlight/Safari suggestions fix below does NOT require SIP and will still work."
    echo ""
  fi

  if ! confirm "Proceed with homecall blocking?"; then
    warn "Skipped homecall blocking"
    return
  fi

  # Disable Spotlight Siri suggestions (works with SIP enabled)
  defaults write com.apple.Spotlight orderedItems -array \
    '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}' \
    '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
    '{"enabled" = 0;"name" = "MENU_DEFINITION";}'
  info "Spotlight suggestions disabled"

  # Safari suggestions (works with SIP enabled)
  defaults write com.apple.Safari UniversalSearchEnabled -bool NO 2>/dev/null || true
  defaults write com.apple.Safari SuppressSearchSuggestions -bool YES 2>/dev/null || true
  info "Safari search suggestions disabled"

  if $sip_enabled; then
    warn "Skipping daemon/agent unload — SIP is enabled (all targets are under /System/Library/)"
  else
    # Use modern launchctl syntax (bootout + disable) instead of deprecated unload -w
    local uid
    uid="$(id -u)"

    for daemon in "${HOMECALL_DAEMONS[@]}"; do
      if sudo launchctl bootout "system/${daemon}" 2>/dev/null; then
        sudo launchctl disable "system/${daemon}" 2>/dev/null || true
        info "Disabled daemon: ${daemon}"
      else
        warn "Could not disable daemon: ${daemon}"
      fi
    done

    for agent in "${HOMECALL_AGENTS[@]}"; do
      if launchctl bootout "gui/${uid}/${agent}" 2>/dev/null; then
        launchctl disable "gui/${uid}/${agent}" 2>/dev/null || true
        info "Disabled agent: ${agent}"
      else
        warn "Could not disable agent: ${agent}"
      fi
    done
  fi

  echo ""
  info "Homecall blocking complete — restart your computer to apply changes"
}

run_hermit() {
  section "Hermit (cashapp/hermit)"
  echo "Hermit is a tool that manages per-project isolated toolchains."
  echo ""
  echo "This will:"
  echo "  - Install Hermit to ~/bin"
  echo "  - Add shell hooks to .zshrc for auto-activation"
  echo ""
  if ! confirm "Install Hermit?"; then
    warn "Skipped Hermit"
    return
  fi

  # --- Install Hermit ---
  if command -v hermit &>/dev/null || [[ -x "${HOME}/bin/hermit" ]]; then
    info "Hermit already installed"
  else
    section "Installing Hermit"
    curl -fsSL https://github.com/cashapp/hermit/releases/download/stable/install.sh | /bin/bash
    info "Hermit installed to ~/bin"
  fi

  # --- Shell hooks ---
  section "Hermit shell hooks"
  local hermit_block
  hermit_block='# Hermit (cashapp/hermit)
PATH=~/bin:$PATH
eval "$(hermit shell-hooks --zsh)"'

  ensure_block "${HOME}/.zshrc" "hermit" "$hermit_block"
  info ".zshrc Hermit block updated (### BEGIN/END hermit)"

  info "Hermit setup complete — restart your terminal or run 'source ~/.zshrc'"
}

run_zsh_setup() {
  section "Zsh Setup (lightweight)"
  echo "Sets up a fast, modern Zsh environment without Oh My Zsh."
  echo ""
  echo "This will install:"
  echo "  - antidote (plugin manager)"
  echo "  - starship (cross-shell prompt)"
  echo "  - zoxide (fast directory jumper, replaces fasd/autojump)"
  echo "  - fzf (fuzzy finder with Ctrl-R history, Ctrl-T file search)"
  echo "  - eza (modern ls replacement with git status)"
  echo "  - direnv (per-directory environment variables)"
  echo ""
  echo "Zsh plugins (via antidote):"
  echo "  - zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions"
  echo "  - zsh-history-substring-search, zsh-async"
  echo "  - alias-tips, zmv"
  echo ""
  if ! confirm "Install Zsh setup?"; then
    warn "Skipped Zsh setup"
    return
  fi

  install_homebrew

  # --- Brew packages ---
  local -a zsh_brews=(
    antidote
    starship
    zoxide
    fzf
    eza
    direnv
  )
  brew_install_list "Zsh tools" "${zsh_brews[@]}"

  # --- fzf keybindings ---
  section "fzf keybindings"
  local fzf_prefix
  fzf_prefix="$(brew --prefix fzf 2>/dev/null || echo "/opt/homebrew/opt/fzf")"
  if [[ -x "${fzf_prefix}/install" ]]; then
    "${fzf_prefix}/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    info "fzf keybindings installed"
  else
    warn "fzf install script not found — keybindings may need manual setup"
  fi

  # --- Plugin list ---
  section "Antidote plugins"
  local plugins_file="${HOME}/.zshplugins"
  cat > "$plugins_file" << 'PLUGINS'
# Zsh users essentials
zsh-users/zsh-autosuggestions
zsh-users/zsh-completions
zsh-users/zsh-history-substring-search
zsh-users/zsh-syntax-highlighting

# Async support
mafredri/zsh-async

# Alias tips
djui/alias-tips
PLUGINS
  info "Plugin list written to ${plugins_file}"

  # --- Generate static plugin file ---
  if command -v antidote &>/dev/null; then
    antidote bundle < "$plugins_file" > "${HOME}/.zsh_plugins.sh"
    info "Antidote plugins bundled to ~/.zsh_plugins.sh"
  else
    warn "antidote not in PATH — run 'antidote bundle < ~/.zshplugins > ~/.zsh_plugins.sh' after restarting"
  fi

  # --- Shell aliases & functions ---
  section "Shell aliases & functions"
  for dotfile in .adrw-aliases .adrw-functions .adrw-highbeam-aliases; do
    if [[ -f "${SCRIPT_DIR}/${dotfile}" ]]; then
      cp "${SCRIPT_DIR}/${dotfile}" "${HOME}/${dotfile}"
      info "Installed ~/${dotfile}"
    else
      warn "${dotfile} not found in ${SCRIPT_DIR}"
    fi
  done

  # --- .zshrc ---
  section "Configuring .zshrc"
  local zshrc="${HOME}/.zshrc"

  # Build the managed block content
  local zshrc_block
  zshrc_block="$(cat << 'ZSHRC'
# Zsh core settings
autoload -U compinit && compinit
autoload -U zmv

# History
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Antidote (plugin manager)
if [[ -r "$(brew --prefix 2>/dev/null)/opt/antidote/share/antidote/antidote.zsh" ]]; then
  source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
  if [[ ! "${HOME}/.zsh_plugins.sh" -nt "${HOME}/.zshplugins" ]]; then
    antidote bundle < "${HOME}/.zshplugins" > "${HOME}/.zsh_plugins.sh"
  fi
  source "${HOME}/.zsh_plugins.sh"
else
  echo >&2 "antidote: not found — install with 'brew install antidote'"
fi

# fzf (fuzzy finder — Ctrl-R for history, Ctrl-T for files)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide (fast directory jumper — use `z` to cd)
eval "$(zoxide init zsh)"

# direnv (per-directory env vars)
eval "$(direnv hook zsh)"

# eza aliases (modern ls with git status)
alias ls="eza"
alias l="eza -la --git"
alias ll="eza -la --git --tree --level=2"
alias lt="eza -la --git --sort=modified"

# Custom aliases & functions
[ -f "${HOME}/.adrw-functions" ] && source "${HOME}/.adrw-functions"
[ -f "${HOME}/.adrw-aliases" ] && source "${HOME}/.adrw-aliases"
[ -f "${HOME}/.adrw-highbeam-aliases" ] && source "${HOME}/.adrw-highbeam-aliases"

# Starship prompt (loaded last)
eval "$(starship init zsh)"
ZSHRC
  )"

  ensure_block "$zshrc" "adrw-dotfiles" "$zshrc_block"
  info ".zshrc managed block updated (content between ### BEGIN/END adrw-dotfiles)"

  # --- Set zsh as default shell ---
  if [[ "$SHELL" != */zsh ]]; then
    section "Default shell"
    if confirm "Set zsh as default shell?"; then
      chsh -s "$(command -v zsh)"
      info "Default shell set to zsh"
    else
      warn "Skipped changing default shell"
    fi
  fi

  info "Zsh setup complete — restart your terminal or run 'source ~/.zshrc'"
}

run_highbeam() {
  section "Highbeam setup"
  install_homebrew

  if [[ ${#BREW_HIGHBEAM[@]} -gt 0 ]]; then
    brew_install_list "Highbeam packages" "${BREW_HIGHBEAM[@]}"
  else
    warn "BREW_HIGHBEAM array is empty — add packages to setup.sh"
  fi

  local dotfile=".adrw-highbeam-aliases"
  if [[ -f "${SCRIPT_DIR}/${dotfile}" ]]; then
    cp "${SCRIPT_DIR}/${dotfile}" "${HOME}/${dotfile}"
    info "Installed ~/${dotfile}"
  else
    warn "${dotfile} not found in ${SCRIPT_DIR}"
  fi

  # Ensure .zshrc sources the aliases file even if run_zsh_setup was not run
  local zshrc="${HOME}/.zshrc"
  local highbeam_block='# Highbeam aliases
[ -f "${HOME}/.adrw-highbeam-aliases" ] && source "${HOME}/.adrw-highbeam-aliases"'
  ensure_block "$zshrc" "highbeam" "$highbeam_block"
  info ".zshrc Highbeam block updated (### BEGIN/END highbeam)"
}

# ===========================================================================
# Main menu
# ===========================================================================

main() {
  install_xcode_cli_tools

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  ADRW .files — macOS Setup${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""
  echo "Select what to set up:"
  echo ""
  echo "  1) Homebrew packages"
  echo "  2) /etc/hosts ad-blocking"
  echo "  3) macOS security hardening"
  echo "  4) macOS UX preferences"
  echo "  5) Homecall blocking"
  echo "  6) Zsh setup (antidote, starship, fzf, zoxide, eza)"
  echo "  7) Hermit (cashapp/hermit — per-project toolchains)"
  echo "  8) Highbeam setup (packages & aliases)"
  echo "  a) All of the above"
  echo "  q) Quit"
  echo ""
  read -r -p "Enter choices (e.g. 1,3 or a): " choices

  if [[ "$choices" == "q" ]]; then
    echo "Bye!"
    exit 0
  fi

  if [[ "$choices" == *"a"* ]]; then
    choices="1,2,3,4,5,6,7,8"
  fi

  IFS=',' read -ra selected <<< "$choices"
  for choice in "${selected[@]}"; do
    choice="$(echo "$choice" | xargs)"
    case "$choice" in
      1) run_homebrew ;;
      2) run_etchosts ;;
      3) run_security ;;
      4) run_macos_prefs ;;
      5) run_homecall ;;
      6) run_zsh_setup ;;
      7) run_hermit ;;
      8) run_highbeam ;;
      *) warn "Unknown selection: ${choice}" ;;
    esac
  done

  echo ""
  info "All done!"
}

main
