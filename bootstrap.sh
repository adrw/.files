# By Andrew Paradi | Source at https://github.com/andrewparadi/.files
#!/usr/bin/env bash

# set up bash to handle errors more aggressively - a "strict mode" of sorts
set -e # give an error if any command finishes with a non-zero exit code
set -u # give an error if we reference unset variables
set -o pipefail # for a pipeline, if any of the commands fail with a non-zero exit code, fail the entire pipeline with that exit code

function status {
  Reset='   tput sgr0'       # Text Reset
  Red='     tput setaf 1'          # Red
  Green='   tput setaf 2'        # Green
  Blue='    tput setaf 4'         # Blue
  div="********************************************************************************"
  scriptname="$(basename "$0")"
  case "$1" in
    a)        echo "" && echo "$($Blue)<|${scriptname:0:1}$($Reset) [ ${2} ] ${div:$((${#2}+9))}" ;;
    b)        echo "$($Green)ok: [ ${2} ] ${div:$((${#2}+9))}$($Reset)" ;;
    s|status) echo "$($Blue)<|${scriptname:0:1}$($Reset) [ ${2} ] ${div:$((${#2}+9))}" ;;
    t|title)  echo "$($Blue)<|${scriptname}$($Reset) [ ${2} ] ${div:$((${#2}+8+${#scriptname}))}" ;;
    e|err)    echo "$($Red)fatal: [ ${2} ] ${div:$((${#2}+12))}$($Reset)" ;;
  esac
}

function safe_download {
  timestamp="`date '+%Y%m%d-%H%M%S'`"
  if [ ! -f "$1" ]; then
    status a "Download ${1}"
    curl -s -o $1 $2
    status b "Download ${1}"
  else
    status a "Update ${1}"
    mv $1 $1.$timestamp
    curl -s -o $1 $2
    if diff -q "$1" "$1.$timestamp" > /dev/null; then rm $1.$timestamp; fi
    status b "Update ${1}"
  fi
}

function safe_source {
  if [[ -z $(grep "$1" "$2") ]]; then echo "source $1" >> $2; fi
}

function show_help {
  status a "❓  Usage :: .files/bootstrap.sh {opts}"
  echo "Options |   Description                       |   Default (or alternate) Values"
  echo "${div}"
  echo "-h      |   Show help menu                    |                         "
  echo "-a      |   Only run Ansible Playbook         |   Def: runs .macos      "
  echo "-d      |   .files/ directory                 |   ${HOME}/.files        "
  echo "-b      |   Homebrew install directory        |   ${HOME}/.homebrew     "
  echo "        |       Homebrew default              |   /usr/local            "
  echo "-i      |   Ansible Inventory                 |   macbox/hosts          "
  echo "-p      |   Ansible Playbook                  |                         "
  echo "        |     - Default: Main Mac environment |   mac_core              "
  echo "        |     - Dev environment (no media)    |   mac_dev               "
  echo "        |     - Homebrew, Atom, Docker...     |   mac_jekyll            "
  echo "        |     - etchost domain blocking       |   mac_etchost_no_animate"
  # echo "        |     - Linux environment             |   linux_core"
  echo "-m      |   Mac App Store email               |   \"\"                  "
  echo "-n      |   Mac App Store password            |   \"\"                  "
  echo "-s      |   Set hostname, turn on Firewall    |                         "
  echo "-t      |   Test env, don't detach Git head   |                         "
  echo "-u      |   User name                         |   me                    "
  err "Learn more at https://github.com/andrewparadi/.files"
  exit 0
}

function secure_hostname_network {
  status a "🔐  Secure network and custom host name"
  read -p "Enter name for your Mac: " MAC_NAME
  echo "  - MAC_NAME $MAC_NAME"
  # randomize MAC address
  sudo ifconfig en0 ether $(openssl rand -hex 6 | sed 's%\(..\)%\1:%g; s%.$%%')

  # turn off network interfaces
  networksetup -setairportpower en0 off

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

  # reboot network interfaces
  networksetup -setairportpower en0 on

  sleep 5
  status b "🔐  Host Name: ${MAC_NAME}. Firewall: On."
}

function mac_bootstrap {
  status a "Bootstrap Script"

  if [[ ! -x /usr/bin/gcc ]]; then
    status a "Install xcode-select (Command Line Tools)"
    xcode-select --install
    status b  "Install xcode-select (Command Line Tools)"
  fi

  if [[ ! -x "$HOMEBREW_DIR/bin/brew" ]]; then
    status a "Install Homebrew"
    mkdir -p $HOMEBREW_DIR && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW_DIR
    status b "Install Homebrew"
  fi

  export PATH=$HOMEBREW_DIR/sbin:$HOMEBREW_DIR/bin:$PATH

  if [[ ! -x $HOMEBREW_DIR/bin/git ]]; then
    status a "Install Git"
    brew install git
    status b "Install Git"
  fi

  if [[ ! -x $HOMEBREW_DIR/bin/ansible ]]; then
    status a "Install Ansible"
    brew install ansible
    status b "Install Ansible"
  fi

  if [[ ! -d $MAIN_DIR ]]; then
    status a "Clone .files"
    git clone https://github.com/andrewparadi/.files.git $MAIN_DIR
    status b "Clone .files"
  elif [[ "$TEST" == false ]]; then
    status a "Decapitate .files (headless mode)"
    cd $MAIN_DIR
    git fetch --all
    git reset --hard origin/master
    git checkout origin/master
    status b "Decapitate .files (headless mode)"
  fi

  # chmod -R 774 $MAIN_DIR
  # chmod +x $MAIN_DIR/bin/shuttle.sh
  # ln -sf $MAIN_DIR/bin/shuttle.sh /usr/local/bin/shuttle
  status b "xcode-select, git, homebrew, ansible"
  if [[ $PLAY == "mac_etchost_no_animate" ]]; then
    status a "ansible-playbook | $PLAY @ $INVENTORY"
    cd "$MAIN_DIR/ansible" && ansible-playbook --ask-sudo-pass -i inventories/$INVENTORY plays/provision/$PLAY.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    status b "ansible-playbook | $PLAY @ $INVENTORY"

    if [ "$ONLY_ANSIBLE" = false ]; then
      status a "no_animate.macos"
      $SCRIPTS/no_animate.macos
      status b "no_animate.macos"
    fi

  elif [[ $PLAY == "mac_jekyll" ]]; then
    status a "ansible-playbook :: $PLAY @ $INVENTORY"
    cd "$MAIN_DIR/ansible" && ansible-playbook --ask-sudo-pass -i inventories/$INVENTORY plays/provision/$PLAY.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    status b "ansible-playbook :: $PLAY @ $INVENTORY"

  else
    status a "ansible-playbook :: $PLAY @ $INVENTORY"
    cd "$MAIN_DIR/ansible" && ansible-playbook --ask-sudo-pass --ask-vault-pass -i inventories/$INVENTORY plays/provision/$PLAY.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    status b "ansible-playbook :: $PLAY @ $INVENTORY"

    if [ "$ONLY_ANSIBLE" = false ]; then
      status a "custom.macos"
      $SCRIPTS/custom.macos
      status b "custom.macos"

      status a ".macos"
      $SCRIPTS/.macos
      status b ".macos"
    fi

    # Only works when system integrity protection is off
    if [[ $(csrutil status) != *enabled* ]]; then
      status a "homecall.sh fixmacos"
      bash $SCRIPTS/homecall.sh fixmacos
      status b "homecall.sh fixmacos"
    fi
  fi

  status a "🍺  Bootstrap Script Fin."
  exit 0
}

function linux_bootstrap {
  status a "Install Linux Base Shell"
  # Bash Powerline Theme
  safe_download ~/.bash-powerline.sh https://raw.githubusercontent.com/riobard/bash-powerline/master/bash-powerline.sh
  safe_source ~/.bash-powerline.sh ~/.bashrc

  # ZSH Powerline Theme
  safe_download ~/.zsh-powerline.sh https://raw.githubusercontent.com/riobard/zsh-powerline/master/zsh-powerline.sh
  safe_source ~/.zsh-powerline.sh ~/.zshrc

  # AP-Aliases
  safe_download ~/.ap-aliases https://raw.githubusercontent.com/andrewparadi/.files/master/ansible/roles/aliases/files/.ap-aliases
  safe_source ~/.ap-aliases ~/.bashrc
  safe_source ~/.ap-aliases ~/.zshrc

  # AP-Functions
  safe_download ~/.ap-functions https://raw.githubusercontent.com/andrewparadi/.files/master/ansible/roles/functions/files/.ap-functions
  safe_source ~/.ap-functions ~/.bashrc
  safe_source ~/.ap-functions ~/.zshrc

  status a "🍺  Fin. Bootstrap Script"
  exit 0
}

status t "Welcome to .files bootstrap!"
status s "Andrew Paradi. https://github.com/andrewparadi/.files"

ONLY_ANSIBLE=false                  # -a
MAIN_DIR="$HOME/.files"             # -d
SCRIPTS="$MAIN_DIR/scripts"
HOMEBREW_DIR="$HOME/.homebrew"      # -b
HOMEBREW_INSTALL_DIR="$HOMEBREW_DIR"
INVENTORY=macbox/hosts              # -i
LINUX=false                         # -l
PLAY=mac_core                       # -p
MAS_EMAIL=                          # -m
MAS_PASSWORD=                       # -n
TEST=false                          # -t
USER_NAME=me                        # -u
SECURE=false                        # -s

status a "📈  Registered Configuration"
while getopts "h?ad:b:i:p:m:n:sltu:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    a)  echo "  - ONLY_ANSIBLE=true"
        ONLY_ANSIBLE=true
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
    l)  echo "  - LINUX => PURE (no ansible)"
        LINUX=true
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
    s)  echo "  - Secure network and custom host name"
        SECURE=true
        ;;
    t)  echo "  - Test Environment (Git Head still attached)"
        TEST=true
        ;;
    u)  echo "  - USER $USER_NAME => $OPTARG"
        USER_NAME=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
echo "Leftovers: $@"

if [[ $SECURE == true ]]; then
  secure_hostname_network
fi

# Determine platform
case "$(uname)" in
    Darwin)   PLATFORM=Darwin
              mac_bootstrap
              ;;
    Linux)    PLATFORM=Linux
              LINUX=true
              linux_bootstrap
              ;;
    *)        PLATFORM=NULL
              ;;
esac

status err "Unknown Error. Maybe invalid platform (Only works on Mac or Linux)."
exit 1
