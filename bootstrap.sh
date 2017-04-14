#!/usr/bin/env bash

function show_help {
  echo ".files/bootstrap.sh {opts}          (default)                     (other)"
  echo "-d {.files/ directory}              ${HOME}/.files"
  echo "-b {homebrew install directory}     ${HOME}/.homebrew       /usr/local"
  echo "-i {ansible inventory}              macbox/hosts"
  echo "-p {ansible playbook}               mac_core                      mac_dev"
  echo "-m {mac app store email}            \"\""
  echo "-n {mac app store password}         \"\""
  echo "-s {run security setup, set hostname}"
  echo "-t {use test environment, no git checkout}"
  echo "-u {user name}                      me"
  exit 0
}

function secure_setup {
  read -p "MAC_NAME: " MAC_NAME
  echo "  - MAC_NAME $MAC_NAME"
  # randomize MAC address
  sudo ifconfig en0 ether $(openssl rand -hex 6 | sed 's%\(..\)%\1:%g; s%.$%%')
  networksetup -setairportpower airport off

  # set computer name (as done via System Preferences → Sharing)
  sudo scutil --set ComputerName "$MAC_NAME"
  sudo scutil --set HostName "$MAC_NAME"
  sudo scutil --set LocalHostName "$MAC_NAME"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$MAC_NAME"

  # enable firewall, logging, and stealth mode
  /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
  /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

  # stop firewall auto-whitelist by all software
  /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
  /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off

  networksetup -setairportpower airport on
  sleep 5
}

set -e
OPTIND=1

MAIN_DIR="$HOME/.files"             # -d
SCRIPTS="$MAIN_DIR/scripts"
HOMEBREW_DIR="$HOME/.homebrew"      # -b
HOMEBREW_INSTALL_DIR="$HOMEBREW_DIR"
INVENTORY=macbox/hosts              # -i
PLAY=mac_core                       # -p
MAS_EMAIL=                          # -m
MAS_PASSWORD=                       # -n
TEST=false                          # -t
USER_NAME=me                        # -u

echo "Running with options..."
while getopts "h?d:b:i:p:m:n:stu:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    d)  echo "  - MAIN_DIR $MAIN_DIR => $OPTARG"
        MAIN_DIR=$OPTARG
        SCRIPTS="$MAIN_DIR/scripts"
        ;;
    b)  echo "  - HOMEBREW_DIR $HOMEBREW_DIR => $OPTARG"
        HOMEBREW_DIR=$OPTARG
        HOMEBREW_INSTALL_DIR="$OPTARG/Homebrew"
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
    t)  echo "  - using test environment"
        TEST=true
        ;;
    u)  echo "  - USER $USER_NAME => $OPTARG"
        USER_NAME=$OPTARG
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

if [[ ! -d $MAIN_DIR ]]; then
  git clone https://github.com/andrewparadi/.files.git $MAIN_DIR
elif [[ "$TEST" == false ]]; then
  cd $MAIN_DIR
  git fetch --all
  git reset --hard origin/master
  git checkout origin/master
fi

# chmod -R 774 $MAIN_DIR
# chmod +x $MAIN_DIR/bin/shuttle.sh
# ln -sf $MAIN_DIR/bin/shuttle.sh /usr/local/bin/shuttle

echo "xcode-select, git, homebrew, ansible [FIN] *************************************"
echo ""
cd "$MAIN_DIR/ansible" && ansible-playbook --ask-sudo-pass --ask-vault-pass -i inventories/$INVENTORY plays/provision/$PLAY.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
echo "ansible-playbook [FIN] *********************************************************"
echo ""
$SCRIPTS/custom.macos
echo "run custom.macos [FIN] *********************************************************"
echo ""
$SCRIPTS/.macos
echo "run .macos [FIN] ***************************************************************"
echo ""
bash $SCRIPTS/homecall.sh fixmacos
echo "run homecall.sh fixmacos [FIN] *************************************************"
echo "[FIN] **************************************************************************"
exit 0
