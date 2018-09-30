#!/usr/bin/env bash
# By Andrew Paradi | Source at https://github.com/adrw/.files

# set up bash to handle errors more aggressively - a "strict mode" of sorts
set -e # give an error if any command finishes with a non-zero exit code
set -u # give an error if we reference unset variables
set -o pipefail # for a pipeline, if any of the commands fail with a non-zero exit code, fail the entire pipeline with that exit code

if [ ! -f ~/.adrw-functions ]; then
  curl -s0 https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/functions/files/.adrw-functions -o ~/.adrw-functions
fi
source ~/.adrw-functions
ADRWL_LEVEL=$ADRWL_ALL
stayalive &
STAY_ALIVE_PID=$!
TRACE "Stay Alive PID: ${STAY_ALIVE_PID}"

bash -c 'figlet -f slant "ADRW .files" 2> /dev/null; echo -n ""'
DEBUG "Welcome to ADRW .files"
DEBUG "" "" "https://github.com/adrw/.files"

function usage {
  cat << EOF
  Usage :: .files/bootstrap.sh <opts>

  Options |   Description                       |   Default (or alternate) Values
  ${div}
  -h      |   Show help menu                    |                         
  -a      |   Only run Ansible Playbook         |   Def: runs .macos      
  -d      |   .files/ directory                 |   ${HOME}/.files        
  -b      |   Homebrew install directory        |   ${HOME}/.homebrew     
          |       Homebrew default              |   /usr/local            
  -i      |   Ansible Inventory                 |   macbox/hosts          
  -p      |   Ansible Playbook                  |                         
          |     - Default: Main Mac environment |   mac_core                        
          |     - Dev environment (no media)    |   mac_dev               
          |     - Homebrew, Atom, Docker...     |   mac_jekyll            
          |     - etchost domain blocking       |   mac_etchost_no_animate
          |     - Linux environment             |   linux_core
  -s      |   Set hostname, turn on Firewall    |                         
  -t      |   Test env, don't detach Git head   |                         
  -u      |   User name                         |   me                    

  Learn more at https://github.com/adrw/.files
EOF
  exit 0
}

function linux_bootstrap {
  DEBUG "Install Linux Base Shell"
  safe_download ~/.adrw-bash-powerline.sh https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/bash/files/.adrw-bash-powerline.sh
  safe_source ~/.adrw-bash-powerline.sh ~/.bashrc

  safe_download ~/.adrw-zsh-powerline.sh https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/zsh/files/.adrw-zsh-powerline.sh
  safe_source ~/.adrw-zsh-powerline.sh ~/.zshrc

  safe_download ~/.adrw-aliases https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/aliases/files/.adrw-aliases
  safe_source ~/.adrw-aliases ~/.bashrc
  safe_source ~/.adrw-aliases ~/.zshrc

  safe_download ~/.adrw-functions https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/functions/files/.adrw-functions
  safe_source ~/.adrw-functions ~/.bashrc
  safe_source ~/.adrw-functions ~/.zshrc

  safe_download ~/.vimrc https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/vim/files/.vimrc
  
  echo "curl -s https://raw.githubusercontent.com/adrw/.files/master/bootstrap.sh | bash -s" > .adrw-update.sh
  chmod +x .adrw-update.sh

  DEBUG "🍺  Fin. Bootstrap Script"
  exit 0
}

function mac_install_dependencies {
  DEBUG "xcode-select, git, homebrew, ansible"

  # todo? replace with https://github.com/elliotweiser/ansible-osx-command-line-tools
  if ! xcode-select -p 2> /dev/null; then
    DEBUG "Install xcode-select (Command Line Tools)"
    xcode-select --install
    INFO  "Install xcode-select (Command Line Tools)"
  fi

  if [[ ! -x "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    DEBUG "Install Homebrew"
    mkdir -p ${HOMEBREW_PREFIX} && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW_PREFIX
    INFO "Install Homebrew"
  fi

  export PATH=${HOMEBREW_PREFIX}/sbin:${HOMEBREW_PREFIX}/bin:${PATH}

  if [[ ! -x ${HOMEBREW_PREFIX}/bin/git ]]; then
    DEBUG "Install Git"
    brew install git
    INFO "Install Git"
  fi

  if [[ ! -x ${HOMEBREW_PREFIX}/bin/ansible ]]; then
    DEBUG "Install Ansible"
    brew install ansible
    INFO "Install Ansible"
  fi

  INFO "xcode-select, git, homebrew, ansible"
}


function run_secure_hostname_network {
  DEBUG "[🔐 Network]" "Secure network and change hostname: $(hostname) => ${HOSTNAME}"
  # randomize MAC address
  sudo ifconfig en0 ether $(openssl rand -hex 6 | sed 's%\(..\)%\1:%g; s%.$%%')

  # turn off network interfaces
  networksetup -setairportpower en0 off

  # set hostname (as done via System Preferences → Sharing)
  sudo scutil --set ComputerName "${HOSTNAME}"
  sudo scutil --set HostName "${HOSTNAME}"
  sudo scutil --set LocalHostName "${HOSTNAME}"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOSTNAME"

  # enable firewall, logging, and stealth mode
  sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
  /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
  /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

  # stop firewall auto-whitelist by all software
  /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
  /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off

  # reboot network interfaces
  networksetup -setairportpower en0 on

  sleep 5
  INFO "Computer Name: ${HOSTNAME}. Firewall: On." && ADRWL
}

function printConfig {
  ADRWL "[CONFIG]" ""
  TRACE "ONLY_ANSIBLE = ${ONLY_ANSIBLE}"
  TRACE "FAST_ASSUME_DEPENDENCIES_INSTALLED = ${FAST_ASSUME_DEPENDENCIES_INSTALLED}"
  TRACE "GIT_DETACH = ${GIT_DETACH}"
  TRACE "MAIN_DIR = ${MAIN_DIR}"
  TRACE "SCRIPTS = ${SCRIPTS}"
  TRACE "HOMEBREW_PREFIX = ${HOMEBREW_PREFIX}"
  TRACE "HOMEBREW_INSTALL_PATH = ${HOMEBREW_INSTALL_PATH}"
  TRACE "ANSIBLE_INVENTORY = ${ANSIBLE_INVENTORY}"
  TRACE "ANSIBLE_PLAYBOOK = ${ANSIBLE_PLAYBOOK}"
  TRACE "ANSIBLE_RUN_VAULT = ${ANSIBLE_RUN_VAULT}"
  TRACE "USER_NAME = ${USER_NAME}"
  TRACE "USER_GROUP = ${USER_GROUP}"
  TRACE "HOSTNAME = ${HOSTNAME}"
  TRACE "SUDO = ${SUDO}"
  TRACE "SECURE_NETWORK = ${SECURE_NETWORK}"
  TRACE "SCRIPTS_FULL_MACOS_CUSTOM = ${SCRIPTS_FULL_MACOS_CUSTOM}"
  TRACE "SCRIPTS_NO_ANIMATE_MACOS_CUSTOM = ${SCRIPTS_NO_ANIMATE_MACOS_CUSTOM}"
  TRACE "SCRIPTS_MACOS_HOMECALL = ${SCRIPTS_MACOS_HOMECALL}"
  ADRWL "" "" ""
}

ONLY_ANSIBLE=false
FAST_ASSUME_DEPENDENCIES_INSTALLED=0
GIT_DETACH=0
MAIN_DIR="${HOME}/.files"
SCRIPTS="${MAIN_DIR}/scripts"
HOMEBREW_PREFIX="${HOME}/.homebrew"
HOMEBREW_INSTALL_PATH="${HOMEBREW_PREFIX}"
ANSIBLE_INVENTORY="macbox/hosts"
ANSIBLE_PLAYBOOK=""
ANSIBLE_RUN_VAULT=0
USER_NAME=$(whoami)
USER_GROUP=$(getUserGroup)
HOSTNAME=$(hostname)
SUDO=0
SECURE_NETWORK=0
SCRIPTS_FULL_MACOS_CUSTOM=0
SCRIPTS_NO_ANIMATE_MACOS_CUSTOM=0
SCRIPTS_MACOS_HOMECALL=0

function processArguments {
  TRACE "[SETUP]" "Register options"
  while getopts "h?ad:b:fgi:l:mnp:rs:u:v" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    a)  TRACE "ONLY_ANSIBLE=true"
        ONLY_ANSIBLE=true
        ;;
    b)  TRACE "HOMEBREW_PREFIX ${HOMEBREW_PREFIX} => ${OPTARG}"
        HOMEBREW_PREFIX=${OPTARG}
        HOMEBREW_INSTALL_PATH="${OPTARG}/Homebrew"
        ;;
    d)  TRACE "MAIN_DIR ${MAIN_DIR} => ${OPTARG}"
        MAIN_DIR=${OPTARG}
        SCRIPTS="${MAIN_DIR}/scripts"
        ;;
    f)  TRACE "FAST_ASSUME_DEPENDENCIES_INSTALLED=true"
        FAST_ASSUME_DEPENDENCIES_INSTALLED=1
        ;;
    g)  TRACE "Stash .files changes and run in Git headless mode"
        GIT_DETACH=1
        ;;
    i)  TRACE "ANSIBLE_INVENTORY ${ANSIBLE_INVENTORY} => ${OPTARG}"
        ANSIBLE_INVENTORY=${OPTARG}
        ;;
    l)  TRACE "ADRWL_LEVEL ${ADRWL_LEVEL} => ${OPTARG}"
        ADRWL_LEVEL=${OPTARG}
        ;;
    m)  TRACE "SCRIPTS_FULL_MACOS_CUSTOM=true"
        TRACE "SUDO=true"
        SCRIPTS_FULL_MACOS_CUSTOM=1
        SUDO=1
        ;;
    n)  TRACE "SCRIPTS_NO_ANIMATE_MACOS_CUSTOM=true"
        TRACE "SUDO=true"
        SCRIPTS_NO_ANIMATE_MACOS_CUSTOM=1
        SUDO=1
        ;;
    p)  TRACE "ANSIBLE_PLAYBOOK ${ANSIBLE_PLAYBOOK} => ${OPTARG}"
        ANSIBLE_PLAYBOOK=${OPTARG}
        ;;
    r)  TRACE "SUDO=true"
        SUDO=1
        ;;    
    s)  TRACE "Run secure network"
        TRACE "Change hostname ${HOSTNAME} => ${OPTARG}"
        TRACE "SUDO=true"
        SUDO=1
        SECURE_NETWORK=1
        HOSTNAME=${OPTARG}
        ;;
    u)  TRACE "USER ${USER_NAME} => ${OPTARG}"
        USER_NAME=${OPTARG}
        HOME="/Users/${USER_NAME}"
        ;;
    v)  TRACE "RUN_VAULT=true"
        ANSIBLE_RUN_VAULT=1
        ;;
    esac
  done

  shift $((OPTIND-1))
  DEBUG "Leftovers: $*"
}

function interactiveArguments {
  # read -p "Next test? [y/n/enter] " -n 1 -r && echo ""

  function qSudo {
    ADRWL "[Q SUDO]" ""
    DEBUG "# Run tasks requiring Sudo permissions?"
    DEBUG "Affected tasks: Secure Network, macOS Customizations, some Ansible roles"
    read -p "[Enter] to skip. Type any character to run related sudo tasks: " -n 1 -r Q_SUDO && echo ""
    if [[ $Q_SUDO != "" ]]; then
      SUDO=1
      NOTICE "Will run Sudo tasks"
    fi
  }
  
  function qSecureNetwork {
    ADRWL "[Q SECURE]" ""
    DEBUG "# Secure your Computer Name and Network Settings?"
    DEBUG "Change your hostname from ${HOSTNAME}, turn on firewall, randomize MAC address"
    read -p "[Enter] to skip. Type to run with new hostname: " -r Q_HOSTNAME
    if [[ $Q_HOSTNAME != "" ]]; then
      HOSTNAME=$Q_HOSTNAME
      SECURE_NETWORK=1
      NOTICE "Will run secure network tasks and rename computer to ${HOSTNAME}"
    fi
  }

  function qUser {
    ADRWL "[Q USER]" ""
    DEBUG "# Run as User: ${USER_NAME}?"
    read -p "[Enter] to skip. Type to overwrite: " -r Q_USER_NAME
    if [[ $Q_USER_NAME != "" ]]; then
      USER_NAME=$Q_USER_NAME
      USER_GROUP=$(getUserGroup)
      NOTICE "Updated User: ${USER_NAME}"
    fi
  }

  function qHomebrew {
    ADRWL "[Q HOMEBREW]" ""
    DEBUG "# Install homebrew packages in: ${HOMEBREW_PREFIX}?"
    DEBUG "Homebrew by default installs in :/usr/local/bin"
    DEBUG ".files instead by default installs in :/${HOME}/.homebrew"
    DEBUG "This maintains separation of packages between users and better security permissions for: /usr/local/bin"
    read -p "[Enter] to install in ${HOMEBREW_PREFIX}. Type to overwrite: " -r Q_HOMEBREW_PREFIX
    if [[ $Q_HOMEBREW_PREFIX != "" ]]; then
      HOMEBREW_PREFIX=$Q_HOMEBREW_PREFIX
      NOTICE "Updated Homebrew Prefix: ${HOMEBREW_PREFIX}"
    fi
  }

  function qAnsible {
    ADRWL "[Q ANSIBLE]" ""
    DEBUG "# Run an Ansible playbook?"
    DEBUG "Choose from one of the playbooks below to run a set of provisioning tasks"
    DEBUG "-  mac_becomes "
    DEBUG "-  mac_clean "
    DEBUG "-  mac_clear_dock "
    DEBUG "-  mac_core "
    DEBUG "-  mac_etchost_no_animate "
    DEBUG "-  mac__jekyll "
    DEBUG "-  mac_second_account "
    DEBUG "-  mac_square "
    DEBUG "-  mac_test_short "
    DEBUG "-  mac_test_full "
    read -p "[Enter] to skip. Type to overwrite: " -r Q_ANSIBLE_PLAYBOOK
    if [[ $ANSIBLE_PLAYBOOK != "" ]]; then
      ANSIBLE_PLAYBOOK=$Q_ANSIBLE_PLAYBOOK
    fi

    DEBUG "# Run included roles that reference encrypted vault?"
    DEBUG "These may include generating ssh/gpg keys and will require the Ansible-Vault password"
    read -p "[Enter] to skip. Type any character to run vault: " -n 1 -r Q_ANSIBLE_RUN_VAULT && echo ""
    if [[ $Q_ANSIBLE_RUN_VAULT != "" ]]; then
      ANSIBLE_RUN_VAULT=1
    fi
  }

  function qMacosCustomizations {
    ADRWL "[Q macOS]" ""
    DEBUG "# Run full set of macOS customizations?"
    DEBUG "Customizations including reducing animation, increasing keyboard click speed...etc"
    read -p "[Enter] to skip. Type any character to run customizations: " -n 1 -r Q_SCRIPTS_FULL_MACOS_CUSTOM && echo ""
    if [[ $Q_SCRIPTS_FULL_MACOS_CUSTOM != "" ]]; then
      SCRIPTS_FULL_MACOS_CUSTOM=1
    else
      DEBUG "# Run smaller set of macOS customizations? Exclusively removes animations"
      read -p "[Enter] to skip. Type any character to run customizations: " -n 1 -r Q_SCRIPTS_NO_ANIMATE_MACOS_CUSTOM && echo ""
      if [[ $Q_SCRIPTS_NO_ANIMATE_MACOS_CUSTOM != "" ]]; then
        SCRIPTS_NO_ANIMATE_MACOS_CUSTOM=1
      fi
    fi
    
    DEBUG "# Turn off macOS homecall processes?"
    if [[ $(csrutil status) != *enabled* ]]; then
      DEBUG "Many macOS processes 'phone home' periodically, this script attempts to stop this."
      read -p "[Enter] to skip. Type any character to run macOS homecall blocking script: " -n 1 -r Q_SCRIPTS_MACOS_HOMECALL && echo ""
      if [[ $Q_SCRIPTS_MACOS_HOMECALL != "" ]]; then
        SCRIPTS_MACOS_HOMECALL=1
      fi
    else
      DEBUG "Your macOS has System Integrity Protection status enabled so the homecall script can't be run."
      DEBUG "To disable and run the script, reboot into Recovery OS and run 'csrutil disable'."
    fi
  }

  DEBUG "Answer the questions below to build your custom install"
  qSudo
  ((SUDO)) && qSecureNetwork
  qUser
  qAnsible
  ((SUDO)) && qMacosCustomizations
  ADRWL "" "" ""
  INFO "Questions Finished!"
}

function mac_bootstrap {
  ((!FAST_ASSUME_DEPENDENCIES_INSTALLED)) && mac_install_dependencies  
  INFO "Required dependencies installed"

  if [[ ! -d ${MAIN_DIR} ]]; then
    git clone https://github.com/adrw/.files.git "${MAIN_DIR}"
    INFO "Clone .files"
  fi

  cd "${MAIN_DIR}"

  ((GIT_DETACH)) && decap && git checkout origin/master

  DEBUG "Starting your custom runbook..."
  ((SUDO)) && ((SECURE_NETWORK)) && run_secure_hostname_network && INFO "Finished Secure Network"
  
  DEBUG "Starting Ansible Playbook ${ANSIBLE_PLAYBOOK} @ ${ANSIBLE_INVENTORY}"
  ((SUDO)) && ((ANSIBLE_RUN_VAULT)) && cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass --ask-vault-pass -i "inventories/${ANSIBLE_INVENTORY}" "plays/provision/${ANSIBLE_PLAYBOOK}.yml" -e "become=true become_skip=false run_vault=true home=${HOME} user_name=${USER_NAME} user_group=${USER_GROUP} homebrew_prefix=${HOMEBREW_PREFIX} homebrew_install_path=${HOMEBREW_INSTALL_PATH}" && echo ""
  ((!SUDO)) && ((ANSIBLE_RUN_VAULT)) && cd "${MAIN_DIR}/ansible" && ansible-playbook -i --ask-vault-pass "inventories/${ANSIBLE_INVENTORY}" "plays/provision/${ANSIBLE_PLAYBOOK}.yml" -e "become=false become_skip=true run_vault=true home=${HOME} user_name=${USER_NAME} user_group=${USER_GROUP} homebrew_prefix=${HOMEBREW_PREFIX} homebrew_install_path=${HOMEBREW_INSTALL_PATH}" && echo ""
  ((SUDO)) && ((!ANSIBLE_RUN_VAULT)) && cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass -i "inventories/${ANSIBLE_INVENTORY}" "plays/provision/${ANSIBLE_PLAYBOOK}.yml" -e "become=true become_skip=false run_vault=false home=${HOME} user_name=${USER_NAME} user_group=${USER_GROUP} homebrew_prefix=${HOMEBREW_PREFIX} homebrew_install_path=${HOMEBREW_INSTALL_PATH}" && echo ""
  ((!SUDO)) && ((!ANSIBLE_RUN_VAULT)) && cd "${MAIN_DIR}/ansible" && ansible-playbook -i "inventories/${ANSIBLE_INVENTORY}" "plays/provision/${ANSIBLE_PLAYBOOK}.yml" -e "become=false become_skip=true run_vault=false home=${HOME} user_name=${USER_NAME} user_group=${USER_GROUP} homebrew_prefix=${HOMEBREW_PREFIX} homebrew_install_path=${HOMEBREW_INSTALL_PATH}" && echo ""
  INFO "Finished Ansible Playbook"

  cd "${MAIN_DIR}"

  ((SUDO)) && ((SCRIPTS_FULL_MACOS_CUSTOM)) && run_script "${SCRIPTS}/custom.macos" && run_script "${SCRIPTS}/.macos"
  ((SUDO)) && ((SCRIPTS_NO_ANIMATE_MACOS_CUSTOM)) && run_script "${SCRIPTS}/no_animate.macos"
  ((SUDO)) && ((SCRIPTS_MACOS_HOMECALL)) && run_script "${SCRIPTS}/homecall.sh fixmacos"
  INFO "Finished macOS Custom Scripts"

  sudo -k
  kill -9 $STAY_ALIVE_PID
  DEBUG "🍺  Fin. Bootstrap Script"
  exit 0
}

# Determine platform and run bootstrap
case "$(uname)" in
    Darwin)   PLATFORM=Darwin
              if [ $# -eq 0 ]; then
                interactiveArguments
              else
                processArguments "$@"
              fi
              printConfig
              mac_bootstrap
              ;;
    Linux)    PLATFORM=Linux
              LINUX=true
              linux_bootstrap
              ;;
    *)        PLATFORM=NULL
              ;;
esac

FATAL "Unknown Error. Maybe invalid platform (Only works on Mac or Linux)."
exit 1
