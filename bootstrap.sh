#!/usr/bin/env bash

function show_help {
  echo ".files/bootstrap.sh {opts}          (default)                     (other)"
  echo "-d {.files/ directory}              ${HOME}/.files"
  echo "-b {homebrew install directory}     ${HOME}/.homebrew       /usr/local"
  echo "-i {ansible inventory}              macbox/hosts"
  echo "-p {ansible playbook}               mac_core                      mac_dev"
  echo "-m {mac app store email}            \"\""
  echo "-n {mac app store password}         \"\""
  echo "-s {run security setup}"
  exit 0
}

function secure_setup {
  name=mbp

  # set computer name (as done via System Preferences → Sharing)
  sudo scutil --set ComputerName "$name"
  sudo scutil --set HostName "$name"
  sudo scutil --set LocalHostName "$name"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$name"

  # enable firewall, logging, and stealth mode
  /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
  /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

  # stop firewall auto-whitelist by all software
  /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
  /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off
}

set -e
OPTIND=1

MAIN_DIR="$HOME/.files"             # -d
HOMEBREW_DIR="$HOME/.homebrew"      # -b
INVENTORY=macbox/hosts              # -i
PLAY=mac_core                       # -p
MAS_EMAIL=                          # -m
MAS_PASSWORD=                       # -n

echo "Running with options..."
while getopts "h?d:b:i:p:m:n:s" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    d)  echo "  - MAIN_DIR $MAIN_DIR => $OPTARG"
        MAIN_DIR=$OPTARG
        ;;
    b)  echo "  - HOMEBREW_DIR $HOMEBREW_DIR => $OPTARG"
        HOMEBREW_DIR=$OPTARG
        ;;
    i)  echo "  - INVENTORY $INVENTORY => $OPTARG"
        INVENTORY=$OPTARG
        ;;
    p)  echo "  - PLAY $PLAY => $OPTARG"
        PLAY=$OPTARG
        ;;
    m)  echo "  - MAS_EMAIL $MAS_EMAIL => $OPTARG"
        MAS_EMAIL=$OPTARG
        ;;
    n)  echo "  - MAS_PASSWORD $MAS_PASSWORD => $OPTARG"
        MAS_PASSWORD=$OPTARG
        ;;
    s)  echo "  - running secure_setup routine"
        secure_setup
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift
echo "Leftovers: $@"
echo ""
echo "[BEGIN] ************************************************************************"

if [[ ! -x /usr/bin/gcc ]]; then
  xcode-select --install
fi

if [[ ! -x "$HOMEBREW_DIR/bin/brew" ]]; then
  mkdir -p $HOMEBREW_DIR && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW_DIR
fi

export PATH=$HOMEBREW_DIR/sbin:$HOMEBREW_DIR/bin:$PATH

if [[ ! -x $HOMEBREW_DIR/bin/git ]]; then
  brew install git
fi

if [[ ! -x $HOMEBREW_DIR/bin/ansible ]]; then
  brew install ansible
fi

echo "xcode-select, git, homebrew, ansible [FIN] *************************************"
echo ""
cd "$MAIN_DIR/ansible" && ansible-playbook --ask-sudo-pass -i inventories/$INVENTORY plays/provision/$PLAY.yml -e "home=${HOME} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
echo "ansible-playbook [FIN] *********************************************************"
exit 0
