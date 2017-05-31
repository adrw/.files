#!/usr/bin/env bash

div="***********************************************************************"
function beg {
  echo ""
  echo "BEG [ ${1} ] ${div:${#1}}"
}

function end {
  echo "FIN [ ${1} ] ${div:${#1}}"
}

function show_help {
  echo ".files/bootstrap.sh {opts}          (default)                     (other)"
  echo "-d {.files/ directory}              ${HOME}/.files"
  echo "-b {homebrew install directory}     ${HOME}/.homebrew       /usr/local"
  echo "-i {ansible inventory}              macbox/hosts"
  echo "-p {ansible playbook}               mac_core"
  echo "      mac    _core    _dev   _etchost_no_animate"
  echo "      linux_"
  echo "-m {mac app store email}            \"\""
  echo "-n {mac app store password}         \"\""
  echo "-s {run security setup, set hostname}"
  echo "-t {use test environment, no git checkout}"
  echo "-u {user name}                      me"
  exit 0
}

function install_linux {
  beg "Install Pure Linux"
  # Bash Powerline Theme
  if [ ! -f ~/.bash-powerline.sh ]; then
    beg "Bash Powerline"
    wget https://raw.githubusercontent.com/riobard/bash-powerline/master/bash-powerline.sh -O ~/.bash-powerline.sh
    echo "source ~/.bash-powerline.sh" >> ~/.bashrc
    end "Bash Powerline"
  fi

  # ZSH Powerline Theme
  if [ ! -f ~/.zsh-powerline.sh ]; then
    beg "ZSH Powerline"
    wget https://raw.githubusercontent.com/riobard/zsh-powerline/master/zsh-powerline.sh -O ~/.zsh-powerline.sh
    echo "source ~/.zsh-powerline.sh" >> ~/.zshrc
    end "ZSH Powerline"
  fi

  # Aliases
  if [ ! -f ~/.ap-aliases ]; then
    beg "Aliases"
    wget https://raw.githubusercontent.com/andrewparadi/.files/master/ansible/roles/aliases/files/.aliases -O ~/.ap-aliases
    echo "source ~/.ap-aliases" >> ~/.bashrc
    echo "source ~/.ap-aliases" >> ~/.zshrc
    end "Aliases"
  fi

  # Functions
  if [ ! -f ~/.ap-functions ]; then
    beg "Functions"
    wget https://raw.githubusercontent.com/andrewparadi/.files/master/ansible/roles/functions/files/.functions -O ~/.ap-functions
    echo "source ~/.ap-functions" >> ~/.bashrc
    echo "source ~/.ap-functions" >> ~/.zshrc
    end "Functions"
  fi

  end "Install Pure Linux"
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
LINUX=false                         # -l
PLAY=mac_core                       # -p
MAS_EMAIL=                          # -m
MAS_PASSWORD=                       # -n
TEST=false                          # -t
USER_NAME=me                        # -u

echo "Running with options..."
while getopts "h?d:b:i:p:m:n:sltu:" opt; do
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

# Determine platform
case "$(uname)" in
    Darwin)   echo "  - PLATFORM = Darwin"
              PLATFORM=Darwin
              ;;
    Linux)    echo "  - PLATFORM = Linux"
              PLATFORM=Linux
              LINUX=true
              install_linux
              ;;
    *)        echo "  - PLATFORM = Unknown"
              PLATFORM=NULL
              ;;
esac

shift $((OPTIND-1))
[ "$1" = "--" ] && shift
echo "Leftovers: $@"
beg "Bootstrap Script"
if [[ ! -x /usr/bin/gcc ]]; then
  beg "xcode-select"
  xcode-select --install
  end  "xcode-select"
fi

if [[ ! -x "$HOMEBREW_DIR/bin/brew" ]]; then
  beg "Install Homebrew"
  mkdir -p $HOMEBREW_DIR && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW_DIR
  end "Install Homebrew"
fi

export PATH=$HOMEBREW_DIR/sbin:$HOMEBREW_DIR/bin:$PATH

if [[ ! -x $HOMEBREW_DIR/bin/git ]]; then
  beg "Install Git"
  brew install git
  end "Install Git"
fi

if [[ ! -x $HOMEBREW_DIR/bin/ansible ]]; then
  beg "Install Ansible"
  brew install ansible
  end "Install Ansible"
fi

if [[ ! -d $MAIN_DIR ]]; then
  beg "Clone .files"
  git clone https://github.com/andrewparadi/.files.git $MAIN_DIR
  end "Clone .files"
elif [[ "$TEST" == false ]]; then
  beg "Decapitate .files (headless mode)"
  cd $MAIN_DIR
  git fetch --all
  git reset --hard origin/master
  git checkout origin/master
  end "Decapitate .files (headless mode)"
fi

# chmod -R 774 $MAIN_DIR
# chmod +x $MAIN_DIR/bin/shuttle.sh
# ln -sf $MAIN_DIR/bin/shuttle.sh /usr/local/bin/shuttle
end "xcode-select, git, homebrew, ansible"
if [[ $PLAY == "mac_etchost_no_animate" ]]; then

  beg "ansible-playbook | $PLAY @ $INVENTORY"
  cd "$MAIN_DIR/ansible" && ansible-playbook --ask-sudo-pass -i inventories/$INVENTORY plays/provision/$PLAY.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
  end "ansible-playbook | $PLAY @ $INVENTORY"

  beg "no_animate.macos"
  $SCRIPTS/no_animate.macos
  end "no_animate.macos"

else

  beg "ansible-playbook | $PLAY @ $INVENTORY"
  cd "$MAIN_DIR/ansible" && ansible-playbook --ask-sudo-pass --ask-vault-pass -i inventories/$INVENTORY plays/provision/$PLAY.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
  end "ansible-playbook | $PLAY @ $INVENTORY"

  beg "custom.macos"
  $SCRIPTS/custom.macos
  end "custom.macos"

  beg ".macos"
  $SCRIPTS/.macos
  end ".macos"

  beg "homecall.sh fixmacos"
  bash $SCRIPTS/homecall.sh fixmacos
  end "homecall.sh fixmacos"

fi

end "Bootstrap Script"
exit 0
