#!/usr/bin/env bash
# By Andrew Paradi | Source at https://github.com/adrw/.files

# set up bash to handle errors more aggressively - a "strict mode" of sorts
set -e # give an error if any command finishes with a non-zero exit code
set -u # give an error if we reference unset variables
set -o pipefail # for a pipeline, if any of the commands fail with a non-zero exit code, fail the entire pipeline with that exit code

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
  -m      |   Mac App Store email               |   \"\"                  
  -n      |   Mac App Store password            |   \"\"                  
  -s      |   Set hostname, turn on Firewall    |                         
  -t      |   Test env, don't detach Git head   |                         
  -u      |   User name                         |   me                    

  Learn more at https://github.com/adrw/.files
EOF
  exit 0
}

function run_secure_hostname_network {
  DEBUG "[🔐 Network]" "Secure network and change computer name: $(hostname) => ${COMPUTER_NAME}"
  # randomize MAC address
  sudo ifconfig en0 ether $(openssl rand -hex 6 | sed 's%\(..\)%\1:%g; s%.$%%')

  # turn off network interfaces
  networksetup -setairportpower en0 off

  # set computer name (as done via System Preferences → Sharing)
  sudo scutil --set ComputerName "${COMPUTER_NAME}"
  sudo scutil --set HostName "${COMPUTER_NAME}"
  sudo scutil --set LocalHostName "${COMPUTER_NAME}"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"

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
  INFO "Computer Name: ${COMPUTER_NAME}. Firewall: On." && ADRWL
}

function mac_install_dependencies {
  DEBUG "xcode-select, git, homebrew, ansible"

  # todo? replace with https://github.com/elliotweiser/ansible-osx-command-line-tools
  if ! xcode-select -p 2> /dev/null; then
    DEBUG "Install xcode-select (Command Line Tools)"
    xcode-select --install
    INFO  "Install xcode-select (Command Line Tools)"
  fi

  if [[ ! -x "${HOMEBREW_DIR}/bin/brew" ]]; then
    DEBUG "Install Homebrew"
    mkdir -p ${HOMEBREW_DIR} && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW_DIR
    INFO "Install Homebrew"
  fi

  export PATH=${HOMEBREW_DIR}/sbin:${HOMEBREW_DIR}/bin:${PATH}

  if [[ ! -x ${HOMEBREW_DIR}/bin/git ]]; then
    DEBUG "Install Git"
    brew install git
    INFO "Install Git"
  fi

  if [[ ! -x ${HOMEBREW_DIR}/bin/ansible ]]; then
    DEBUG "Install Ansible"
    brew install ansible
    INFO "Install Ansible"
  fi

  INFO "xcode-select, git, homebrew, ansible"
}

function mac_scripts {
  DEBUG "scripts | ${ANSIBLE_PLAYBOOK} @ ${ANSIBLE_INVENTORY}"
  case "${ANSIBLE_PLAYBOOK}" in
  "mac_core"|"mac_square"|"mac_dev"|"mac_clean"|"mac_test_full"|"mac_test_short")
    run_script ${SCRIPTS}/custom.macos
    run_script ${SCRIPTS}/.macos
    if [[ $(csrutil status) != *enabled* ]]; then
      run_script ${SCRIPTS}/homecall.sh fixmacos
    fi
    ;;
  "mac_etchost_no_animate"|"mac_second_account")
    run_script ${SCRIPTS}/no_animate.macos
    ;;
  *)
    ERROR "no scripts"
  esac
  INFO "scripts | ${ANSIBLE_PLAYBOOK} @ ${ANSIBLE_INVENTORY}"
}

function mac_bootstrap {
  DEBUG "Bootstrap Script"

  mac_install_dependencies

  DEBUG "git/.files -> ${MAIN_DIR}"
  if [[ ! -d ${MAIN_DIR} ]]; then
    DEBUG "Clone .files"
    git clone https://github.com/adrw/.files.git ${MAIN_DIR}
    INFO "Clone .files"
  elif [[ "${TEST}" == false ]]; then
    # TODO Delete headless mode
    DEBUG "Decapitate .files (headless mode)"
    # cd ${MAIN_DIR}
    # git fetch --all
    # git reset --hard origin/master
    # git checkout origin/master
    # INFO "Decapitate .files (headless mode)"
  fi
  INFO "git/.files -> ${MAIN_DIR}"

  DEBUG "ansible-playbook | ${ANSIBLE_PLAYBOOK} @ ${ANSIBLE_INVENTORY}"
  case "${ANSIBLE_PLAYBOOK}" in
  "mac_core"|"mac_square")
    cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass --ask-vault-pass -i inventories/${ANSIBLE_INVENTORY} plays/provision/${ANSIBLE_PLAYBOOK}.yml -e "home=${HOME} user_name=${USER_NAME} user_group=$(getUserGroup) homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  "mac_etchost_no_animate"|"mac_jekyll"|"mac_clean")
    cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass -i inventories/${ANSIBLE_INVENTORY} plays/provision/${ANSIBLE_PLAYBOOK}.yml -e "home=${HOME} user_name=${USER_NAME} user_group=$(getUserGroup) homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  "mac_test_full"|"mac_test_short"|"mac_second_account")
    cd "${MAIN_DIR}/ansible" && ansible-playbook -i inventories/${ANSIBLE_INVENTORY} plays/provision/${ANSIBLE_PLAYBOOK}.yml -e "home=${HOME} user_name=${USER_NAME} user_group=$(getUserGroup) homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  *)
    ERROR "no matching play for ${ANSIBLE_PLAYBOOK}"
  esac
  INFO "ansible-playbook | ${ANSIBLE_PLAYBOOK} @ ${ANSIBLE_INVENTORY}"

  if [ "${ONLY_ANSIBLE}" = false ]; then
    mac_scripts
  fi

  # TODO make this an option, not default since if it fails at any point or doesn't have ssh keys then pulling won't work anymore
  DEBUG "${MAIN_DIR} git remote https:->git:"
  cd ${MAIN_DIR}
  git remote remove origin
  git remote add origin git@github.com:adrw/.files.git
  INFO "${MAIN_DIR} git remote https:->git:"

  sudo -k # remove sudo permissions
  DEBUG "🍺  Fin. Bootstrap Script"
  exit 0
}

function linux_bootstrap {
  DEBUG "Install Linux Base Shell"
  # ADRW Bash Powerline Theme
  safe_download ~/.adrw-bash-powerline.sh https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/bash/files/.adrw-bash-powerline.sh
  safe_source ~/.adrw-bash-powerline.sh ~/.bashrc

  # ADRW ZSH Powerline Theme
  safe_download ~/.adrw-zsh-powerline.sh https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/zsh/files/.adrw-zsh-powerline.sh
  safe_source ~/.adrw-zsh-powerline.sh ~/.zshrc

  # ADRW Aliases
  safe_download ~/.adrw-aliases https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/aliases/files/.adrw-aliases
  safe_source ~/.adrw-aliases ~/.bashrc
  safe_source ~/.adrw-aliases ~/.zshrc

  # ADRW Functions
  safe_download ~/.adrw-functions https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/functions/files/.adrw-functions
  safe_source ~/.adrw-functions ~/.bashrc
  safe_source ~/.adrw-functions ~/.zshrc

  # ADRW .vimrc
  safe_download ~/.vimrc https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/vim/files/.vimrc
  
  echo "curl -s https://raw.githubusercontent.com/adrw/.files/master/bootstrap.sh | bash -s" > .ap-update.sh
  chmod +x .ap-update.sh

  DEBUG "🍺  Fin. Bootstrap Script"
  exit 0
}

ONLY_ANSIBLE=false                  # -a
MAIN_DIR="${HOME}/.files"             # -d
SCRIPTS="${MAIN_DIR}/scripts"
HOMEBREW_DIR="${HOME}/.homebrew"      # -b
HOMEBREW_INSTALL_DIR="${HOMEBREW_DIR}"
ANSIBLE_INVENTORY=macbox/hosts              # -i
ANSIBLE_PLAYBOOK=mac_core                       # -p
MAS_EMAIL=                          # -m
MAS_PASSWORD=                       # -n
TEST=false                          # -t
USER_NAME=$(whoami)                 # -u
COMPUTER_NAME=$(hostname)
SUDO=0
SECURE_NETWORK=0
FULL_MACOS_CUSTOM=0
NO_ANIMATE_MACOS_CUSTOM=0
MACOS_HOMECALL=0

function getUserGroup { 
  id -Gn "$USER_NAME" | cut -d " " -f1 
}

function processArguments {
  DEBUG "📈  Registered Configuration"
  while getopts "h?ad:b:i:p:m:n:stu:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    a)  DEBUG "  - ONLY_ANSIBLE=true"
        ONLY_ANSIBLE=true
        ;;
    d)  DEBUG "  - MAIN_DIR ${MAIN_DIR} => ${OPTARG}"
        MAIN_DIR=${OPTARG}
        SCRIPTS="${MAIN_DIR}/scripts"
        ;;
    b)  DEBUG "  - HOMEBREW_DIR ${HOMEBREW_DIR} => ${OPTARG}"
        HOMEBREW_DIR=${OPTARG}
        HOMEBREW_INSTALL_DIR="${OPTARG}/Homebrew"
        ;;
    i)  DEBUG "  - ANSIBLE_INVENTORY ${ANSIBLE_INVENTORY} => ${OPTARG}"
        ANSIBLE_INVENTORY=${OPTARG}
        ;;
    p)  DEBUG "  - ANSIBLE_PLAYBOOK ${ANSIBLE_PLAYBOOK} => ${OPTARG}"
        ANSIBLE_PLAYBOOK=${OPTARG}
        ;;
    m)  DEBUG "  - MAS_EMAIL ${MAS_EMAIL} => ${OPTARG}"
        MAS_EMAIL=$OPTARG
        ;;
    n)  DEBUG "  - MAS_PASSWORD ${MAS_PASSWORD} => ${OPTARG}"
        MAS_PASSWORD=${OPTARG}
        ;;
    s)  DEBUG "  - Secure network and custom host name"
        SECURE_NETWORK=1
        ;;
    t)  DEBUG "  - Test Environment (Git Head still attached)"
        TEST=true
        ;;
    u)  DEBUG "  - USER ${USER_NAME} => ${OPTARG}"
        USER_NAME=${OPTARG}
        HOME="/Users/${USER_NAME}"
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
    read -p "[Enter] to skip. Type any character to run related sudo tasks: " -n 1 -r Q_SUDO
    if [[ $Q_SUDO != "" ]]; then
      SUDO=1
    fi
  }
  
  function qSecureNetwork {
    ADRWL "[Q SECURE]" ""
    DEBUG "# Secure your Computer Name and Network Settings?"
    DEBUG "Change your computer name from ${COMPUTER_NAME}, turn on firewall, randomize MAC address"
    read -p "[Enter] to skip. Type to run with new computer name: " -r Q_COMPUTER_NAME
    if [[ $Q_COMPUTER_NAME != "" ]]; then
      COMPUTER_NAME=$Q_COMPUTER_NAME
      SECURE_NETWORK=1
    fi
  }

  function qUser {
    ADRWL "[Q USER]" ""
    DEBUG "# Run as User: ${USER_NAME}?"
    read -p "[Enter] to skip. Type to overwrite: " -r Q_USER_NAME
    if [[ $Q_USER_NAME != "" ]]; then
      USER_NAME=$Q_USER_NAME
      WARN "Updated User: ${USER_NAME}"
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
  }

  function qMacosCustomizations {
    ADRWL "[Q macOS]" ""
    DEBUG "# Run full set of macOS customizations?"
    DEBUG "Customizations including reducing animation, increasing keyboard click speed...etc"
    read -p "[Enter] to skip. Type any character to run customizations: " -n 1 -r Q_FULL_MACOS_CUSTOM
    if [[ $Q_FULL_MACOS_CUSTOM != "" ]]; then
      FULL_MACOS_CUSTOM=1
    else
      DEBUG "# Run smaller set of macOS customizations? Exclusively removes animations"
      read -p "[Enter] to skip. Type any character to run customizations: " -n 1 -r Q_NO_ANIMATE_MACOS_CUSTOM
      if [[ $Q_NO_ANIMATE_MACOS_CUSTOM != "" ]]; then
        NO_ANIMATE_MACOS_CUSTOM=1
      fi
    fi
    
    DEBUG "# Turn off macOS homecall processes?"
    if [[ $(csrutil status) != *enabled* ]]; then
      DEBUG "Many macOS processes 'phone home' periodically, this script attempts to stop this."
      read -p "[Enter] to skip. Type any character to run macOS homecall blocking script: " -n 1 -r Q_MACOS_HOMECALL
      if [[ $Q_MACOS_HOMECALL != "" ]]; then
        MACOS_HOMECALL=1
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
  
  # Run Custom Runbook
  ((SUDO)) && ((FULL_MACOS_CUSTOM)) && run_script "${SCRIPTS}/custom.macos" && run_script "${SCRIPTS}/.macos"
  ((SUDO)) && ((NO_ANIMATE_MACOS_CUSTOM)) && run_script "${SCRIPTS}/no_animate.macos"
  ((SUDO)) && ((MACOS_HOMECALL)) && run_script "${SCRIPTS}/homecall.sh fixmacos"
  ((SUDO)) && ((SECURE_NETWORK)) && secure_hostname_network





  
  # cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass --ask-vault-pass -i inventories/${ANSIBLE_INVENTORY} plays/provision/${ANSIBLE_PLAYBOOK}.yml -e "home=${HOME} user_name=${USER_NAME} user_group=$(getUserGroup) homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
  
}
 

if [ ! -f ~/.adrw-functions ]; then
  curl -s0 https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/functions/files/.adrw-functions -o ~/.adrw-functions
fi
source ~/.adrw-functions

bash -c 'figlet -f slant "ADRW .files" 2> /dev/null; echo -n ""'
DEBUG "Welcome to ADRW .files"
DEBUG "" "" "https://github.com/adrw/.files"

# Determine platform
case "$(uname)" in
    Darwin)   PLATFORM=Darwin
              if [ $# -eq 0 ]; then
                interactiveArguments
              else
                processArguments "$@"
                ((SECURE_NETWORK)) && run_secure_hostname_network
              fi
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
