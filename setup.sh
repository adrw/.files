#!/usr/bin/env bash
# macOS setup script — interactive, menu-driven
# Source: https://github.com/adrw/.files

set -euo pipefail

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
  certbot          # DEPRECATED? — rarely needed on personal machines, more for servers
  cheat            # DEPRECATED? — community cheatsheets; tldr is similar and more maintained
  coreutils
  exiftool
  figlet
  git-quick-stats
  gh
  hub              # DEPRECATED — gh (GitHub CLI) has replaced hub's functionality
  htop
  jhead
  jo               # DEPRECATED? — jq alone covers most JSON needs
  jq
  neofetch         # DEPRECATED — archived by author in 2024, consider fastfetch
  node
  openssl
  pngquant
  pyenv
  python
  python3
  ripgrep
  shellcheck
  speedtest-cli    # DEPRECATED? — Ookla now has an official `speedtest` brew package
  tldr
  travis           # DEPRECATED — Travis CI has declined significantly since 2020
  tree
  wget
  yarn             # DEPRECATED? — modern Node ships with corepack/pnpm, yarn classic is legacy
)

CASK_DEVELOPMENT=(
  docker
  insomnia         # DEPRECATED? — acquired by Kong, many users migrated to Bruno or Hoppscotch
  jetbrains-toolbox
  ngrok
  postico
  visual-studio-code
)

CASK_PRODUCTIVITY=(
  adobe-acrobat-reader
  barrier          # DEPRECATED? — project has had minimal maintenance since 2022, consider input-leap (the active fork)
  basecamp         # DEPRECATED? — Basecamp no longer ships a native Mac app, web-only now
  brave-browser-dev
  firefox-developer-edition
  google-chrome
  notion
  signal
  slack
  todoist
  tuple
)

CASK_TOOLS=(
  alfred
  appcleaner
  bitwarden
  bitwarden-cli
  charles
  gfxcardstatus    # DEPRECATED — only useful on older Macs with dual GPUs (pre-M1), no Apple Silicon support
  hiddenbar        # DEPRECATED — unmaintained since 2022, consider ice (actively maintained)
  karabiner-elements
  keymapp
  meetingbar
  monitorcontrol
  protonvpn
  quitter          # DEPRECATED? — last updated 2019 by Marco Arment, still works but unmaintained
  rectangle
  the-unarchiver
  utc-menu-clock   # DEPRECATED? — macOS now natively supports showing seconds/UTC in menu bar clock
  viscosity
  xbar
)

CASK_MEDIA=(
  calibre
  imagealpha       # DEPRECATED? — pngquant CLI does the same thing, imagealpha is just a GUI wrapper
  openaudible
  mediahuman-audio-converter
  musicbrainz-picard
  spotify
  transmission
  vlc
)

CASK_FONTS=(
  font-fira-code
  font-fira-mono-for-powerline  # DEPRECATED? — Nerd Fonts patches are more common now
  font-fontawesome
  font-jetbrains-mono
  font-poppins
  font-poppins-latin             # DEPRECATED? — font-poppins already includes latin glyphs
  font-sans-forgetica
)

CASK_BACKUP=(
  synology-drive
)

# ---------------------------------------------------------------------------
# /etc/hosts blocklist URLs (Steven Black)
# ---------------------------------------------------------------------------
HOSTS_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-social/hosts"

CUSTOM_FACEBOOK_HOSTS="
# Facebook (custom — blocks main site, allows messenger.com)
0.0.0.0 facebook.com
0.0.0.0 m.facebook.com
0.0.0.0 www.facebook.com
"

CUSTOM_MEDIA_HOSTS="
# Media
0.0.0.0 youtube.com
0.0.0.0 www.youtube.com
0.0.0.0 netflix.com
0.0.0.0 www.netflix.com

# Reddit
0.0.0.0 reddit.com
0.0.0.0 www.reddit.com

# News
0.0.0.0 9to5mac.com
0.0.0.0 arstechnica.com
0.0.0.0 appleinsider.com
0.0.0.0 www.cnn.com
0.0.0.0 www.dailywire.com
0.0.0.0 financialpost.com
0.0.0.0 gizmodo.com
0.0.0.0 nationalpost.com
0.0.0.0 www.nytimes.com
0.0.0.0 www.macrumors.com
0.0.0.0 theglobeandmail.com
0.0.0.0 www.theglobeandmail.com
0.0.0.0 beta.theglobeandmail.com
0.0.0.0 www.beta.theglobeandmail.com
0.0.0.0 theoutline.com
0.0.0.0 www.theverge.com
0.0.0.0 www.zerohedge.com

# Shopping
0.0.0.0 www.realtor.ca
"

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
    if brew list --formula "$clean" &>/dev/null || brew list --cask "$clean" &>/dev/null; then
      warn "${clean} (already installed)"
    else
      echo -e "  Installing ${BOLD}${clean}${NC}..."
      if brew install "$clean" 2>/dev/null || brew install --cask "$clean" 2>/dev/null; then
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
  echo "This will download Steven Black's unified hosts list (ads + gambling + porn + social)"
  echo "and append custom Facebook/media blocks, then install to /etc/hosts."
  echo ""
  if ! confirm "Install /etc/hosts blocklist?"; then
    warn "Skipped /etc/hosts"
    return
  fi

  local tmpfile
  tmpfile="$(mktemp)"

  echo "Downloading hosts list..."
  if ! curl -fsSL "$HOSTS_URL" -o "$tmpfile"; then
    err "Failed to download hosts list"
    rm -f "$tmpfile"
    return 1
  fi

  # Append custom blocks
  echo "$CUSTOM_FACEBOOK_HOSTS" >> "$tmpfile"
  echo "$CUSTOM_MEDIA_HOSTS" >> "$tmpfile"

  # Backup existing hosts file
  if [[ -f /etc/hosts ]]; then
    sudo cp /etc/hosts "/etc/hosts.backup.$(date +%Y%m%d%H%M%S)"
    info "Backed up /etc/hosts"
  fi

  sudo cp "$tmpfile" /etc/hosts
  rm -f "$tmpfile"

  # Flush DNS cache
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder 2>/dev/null || true

  info "/etc/hosts installed with ad-blocking ($(wc -l < /etc/hosts | xargs) lines)"
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
  echo "  - Disable Bonjour multicast advertising"
  echo "  - Show hidden files and ~/Library in Finder"
  echo "  - Disable Spotlight/Siri suggestions and web search"
  echo "  - Disable Captive Portal assistant"
  echo ""
  if ! confirm "Apply security hardening?"; then
    warn "Skipped security hardening"
    return
  fi

  sudo -v
  # Keep sudo alive
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  local sudo_pid=$!

  # --- Firewall ---
  section "Firewall"
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off
  sudo pkill -HUP socketfilterfw 2>/dev/null || true
  info "Firewall enabled with stealth mode, logging on, auto-whitelist off"

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
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0
  info "Password required immediately on sleep/screensaver"

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

  # --- Bonjour ---
  sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool YES
  info "Bonjour multicast advertising disabled"

  # --- Captive Portal ---
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false
  info "Captive Portal assistant disabled"

  # --- Spotlight/Siri ---
  section "Spotlight & Siri Privacy"
  defaults write com.apple.Safari UniversalSearchEnabled -bool NO 2>/dev/null || true
  defaults write com.apple.Safari SuppressSearchSuggestions -bool YES 2>/dev/null || true
  defaults write com.apple.Safari WebsiteSpecificSearchEnabled -bool NO 2>/dev/null || true
  info "Safari search suggestions and web search disabled"

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
  defaults write ~/Library/Preferences/com.apple.AppleMultitouchTrackpad.plist ActuationStrength 0
  info "3-finger drag enabled, tracking speed increased, silent click on"

  # --- Menu bar ---
  defaults write com.apple.menuextra.battery ShowPercent -string "YES" 2>/dev/null || true
  info "Battery percentage shown"

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
  echo "Note: SIP must be disabled for this to work on system LaunchDaemons."
  echo ""

  if csrutil status 2>/dev/null | grep -q "enabled"; then
    warn "SIP is enabled — homecall blocking may not work for system daemons."
    echo "To disable SIP: reboot into Recovery OS and run 'csrutil disable'."
    echo ""
    if ! confirm "Try anyway?"; then
      warn "Skipped homecall blocking"
      return
    fi
  else
    if ! confirm "Disable phoning-home daemons/agents?"; then
      warn "Skipped homecall blocking"
      return
    fi
  fi

  # Disable Spotlight Siri suggestions
  defaults write com.apple.Spotlight orderedItems -array \
    '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}' \
    '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
    '{"enabled" = 0;"name" = "MENU_DEFINITION";}'
  info "Spotlight suggestions disabled"

  for daemon in "${HOMECALL_DAEMONS[@]}"; do
    if sudo launchctl unload -w "/System/Library/LaunchDaemons/${daemon}.plist" 2>/dev/null; then
      info "Disabled daemon: ${daemon}"
    else
      warn "Could not disable daemon: ${daemon}"
    fi
  done

  for agent in "${HOMECALL_AGENTS[@]}"; do
    if launchctl unload -w "/System/Library/LaunchAgents/${agent}.plist" 2>/dev/null; then
      info "Disabled agent: ${agent}"
    else
      warn "Could not disable agent: ${agent}"
    fi
  done

  echo ""
  info "Homecall blocking complete — restart your computer to apply changes"
}

# ===========================================================================
# Main menu
# ===========================================================================

main() {
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
  echo "  a) All of the above"
  echo "  q) Quit"
  echo ""
  read -r -p "Enter choices (e.g. 1,3 or a): " choices

  if [[ "$choices" == "q" ]]; then
    echo "Bye!"
    exit 0
  fi

  if [[ "$choices" == *"a"* ]]; then
    choices="1,2,3,4,5"
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
      *) warn "Unknown selection: ${choice}" ;;
    esac
  done

  echo ""
  info "All done!"
}

main
