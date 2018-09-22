#!/usr/bin/env bash
# By Andrew Paradi | Source at https://github.com/adrw/.files

# set up bash to handle errors more aggressively - a "strict mode" of sorts
set -e # give an error if any command finishes with a non-zero exit code
set -u # give an error if we reference unset variables
set -o pipefail # for a pipeline, if any of the commands fail with a non-zero exit code, fail the entire pipeline with that exit code

# ADRW Logging
Reset="$(tput sgr0)"            # Text Reset
Red="$(tput setaf 1)"           # Red
Green="$(tput setaf 2)"         # Green
Yellow="$(tput setaf 3)"        # Yellow
Blue="$(tput setaf 4)"          # Blue
_start="$Blue<|$Reset"
_end="$Blue|>$Reset"

function FATAL {
  echo "${_start}[$(date +'%Y-%m-%d %T')][${Red}FATAL${Reset}]${_end} $*"
}

function ERROR {
  echo "${_start}[$(date +'%Y-%m-%d %T')][${Red}ERROR${Reset}]${_end} $*"
}

function WARN {
  echo "${_start}[$(date +'%Y-%m-%d %T')][${Yellow}WARN${Reset}]${_end} $*"
}

function INFO {
  echo "${_start}[$(date +'%Y-%m-%d %T')][${Green}INFO${Reset}]${_end} $*"
}

function DEBUG {
  echo "${_start}[$(date +'%Y-%m-%d %T')][${Blue}DEBUG${Reset}]${_end} $*"
}

function TRACE {
  echo "${_start}[$(date +'%Y-%m-%d %T')][${Blue}Trace${Reset}]${_end} $*"
}

function LOG {
  echo "${_start}[$(date +'%Y-%m-%d %T')][${Red}status${Reset}]${_end} $*"
}

function safe_download {
  timestamp="`date '+%Y%m%d-%H%M%S'`"
  if [ ! -f "$1" ]; then
    LOG a "Download ${1}"
    curl -s -o $1 $2
    LOG b "Download ${1}"
  else
    LOG a "Update ${1}"
    mv $1 $1.$timestamp
    curl -s -o $1 $2
    if diff -q "$1" "$1.$timestamp" > /dev/null; then rm $1.$timestamp; fi
    LOG b "Update ${1}"
  fi
}

function safe_source {
  if [[ -z $(grep "$1" "$2") ]]; then echo "source $1" >> $2; fi
}

function run_script {
  exec=$*
  script=$1
  name=$(basename ${script})
  LOG a "${name}"
  ${exec}
  LOG b "${name}"
}

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

function secure_hostname_network {
  DEBUG "🔐  Secure network and change computer name: $(hostname) => ${COMPUTER_NAME}"
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
  INFO "🔐  Computer Name: ${COMPUTER_NAME}. Firewall: On."
}

function mac_install_dependencies {
  LOG a "xcode-select, git, homebrew, ansible"

  # todo? replace with https://github.com/elliotweiser/ansible-osx-command-line-tools
  if ! xcode-select -p 2> /dev/null; then
    LOG a "Install xcode-select (Command Line Tools)"
    xcode-select --install
    LOG b  "Install xcode-select (Command Line Tools)"
  fi

  if [[ ! -x "${HOMEBREW_DIR}/bin/brew" ]]; then
    LOG a "Install Homebrew"
    mkdir -p ${HOMEBREW_DIR} && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW_DIR
    LOG b "Install Homebrew"
  fi

  export PATH=${HOMEBREW_DIR}/sbin:${HOMEBREW_DIR}/bin:${PATH}

  if [[ ! -x ${HOMEBREW_DIR}/bin/git ]]; then
    LOG a "Install Git"
    brew install git
    LOG b "Install Git"
  fi

  if [[ ! -x ${HOMEBREW_DIR}/bin/ansible ]]; then
    LOG a "Install Ansible"
    brew install ansible
    LOG b "Install Ansible"
  fi

  LOG b "xcode-select, git, homebrew, ansible"
}

function mac_scripts {
  LOG a "scripts | ${PLAY} @ ${INVENTORY}"
  case "${PLAY}" in
  "mac_core"|"mac_square"|"mac_dev"|"mac_clean"|"mac_test_full"|"mac_test_short")
    run_script ${SCRIPTS}/custom.macos
    run_script ${SCRIPTS}/.macos
    if [[ $(csrutil LOG) != *enabled* ]]; then
      run_script ${SCRIPTS}/homecall.sh fixmacos
    fi
    ;;
  "mac_etchost_no_animate"|"mac_second_account")
    run_script ${SCRIPTS}/no_animate.macos
    ;;
  *)
    LOG e "no scripts"
  esac
  LOG b "scripts | ${PLAY} @ ${INVENTORY}"
}

function mac_bootstrap {
  LOG a "Bootstrap Script"

  mac_install_dependencies

  LOG a "git/.files -> ${MAIN_DIR}"
  if [[ ! -d ${MAIN_DIR} ]]; then
    LOG a "Clone .files"
    git clone https://github.com/adrw/.files.git ${MAIN_DIR}
    LOG b "Clone .files"
  elif [[ "${TEST}" == false ]]; then
    # TODO Delete headless mode
    LOG a "Decapitate .files (headless mode)"
    # cd ${MAIN_DIR}
    # git fetch --all
    # git reset --hard origin/master
    # git checkout origin/master
    # LOG b "Decapitate .files (headless mode)"
  fi
  LOG b "git/.files -> ${MAIN_DIR}"

  LOG a "ansible-playbook | ${PLAY} @ ${INVENTORY}"
  case "${PLAY}" in
  "mac_core"|"mac_square")
    cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass --ask-vault-pass -i inventories/${INVENTORY} plays/provision/${PLAY}.yml -e "home=${HOME} user_name=${USER_NAME} user_group=$(getUserGroup) homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  "mac_etchost_no_animate"|"mac_jekyll"|"mac_clean")
    cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass -i inventories/${INVENTORY} plays/provision/${PLAY}.yml -e "home=${HOME} user_name=${USER_NAME} user_group=$(getUserGroup) homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  "mac_test_full"|"mac_test_short"|"mac_second_account")
    cd "${MAIN_DIR}/ansible" && ansible-playbook -i inventories/${INVENTORY} plays/provision/${PLAY}.yml -e "home=${HOME} user_name=${USER_NAME} user_group=$(getUserGroup) homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  *)
    LOG e "no matching play for ${PLAY}"
  esac
  LOG b "ansible-playbook | ${PLAY} @ ${INVENTORY}"

  if [ "${ONLY_ANSIBLE}" = false ]; then
    mac_scripts
  fi

  # TODO make this an option, not default since if it fails at any point or doesn't have ssh keys then pulling won't work anymore
  LOG a "${MAIN_DIR} git remote https:->git:"
  cd ${MAIN_DIR}
  git remote remove origin
  git remote add origin git@github.com:adrw/.files.git
  LOG b "${MAIN_DIR} git remote https:->git:"

  sudo -k # remove sudo permissions
  LOG a "🍺  Fin. Bootstrap Script"
  exit 0
}

function linux_bootstrap {
  LOG a "Install Linux Base Shell"
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

  LOG a "🍺  Fin. Bootstrap Script"
  exit 0
}


bash -c 'figlet -f slant "ADRW .files" 2> /dev/null; echo -n ""'
DEBUG "Welcome to ADRW .files"
DEBUG "https://github.com/adrw/.files"

ONLY_ANSIBLE=false                  # -a
MAIN_DIR="${HOME}/.files"             # -d
SCRIPTS="${MAIN_DIR}/scripts"
HOMEBREW_DIR="${HOME}/.homebrew"      # -b
HOMEBREW_INSTALL_DIR="${HOMEBREW_DIR}"
INVENTORY=macbox/hosts              # -i
PLAY=mac_core                       # -p
MAS_EMAIL=                          # -m
MAS_PASSWORD=                       # -n
TEST=false                          # -t
USER_NAME=$(whoami)                 # -u
SECURE=false                        # -s
COMPUTER_NAME=$(hostname)

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
    i)  DEBUG "  - INVENTORY ${INVENTORY} => ${OPTARG}"
        INVENTORY=${OPTARG}
        ;;
    p)  DEBUG "  - PLAY ${PLAY} => ${OPTARG}"
        PLAY=${OPTARG}
        ;;
    m)  DEBUG "  - MAS_EMAIL ${MAS_EMAIL} => ${OPTARG}"
        MAS_EMAIL=$OPTARG
        ;;
    n)  DEBUG "  - MAS_PASSWORD ${MAS_PASSWORD} => ${OPTARG}"
        MAS_PASSWORD=${OPTARG}
        ;;
    s)  DEBUG "  - Secure network and custom host name"
        SECURE=true
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
  DEBUG "Answer the 14 questions below to build your custom install"

  # Secure Network
  DEBUG "# Secure your Computer Name and Network Settings?"
  DEBUG "Change your computer name from ${COMPUTER_NAME}, turn on firewall, randomize MAC address"
  read -p "[Enter] to skip. Type to run with new computer name: " -r Q_COMPUTER_NAME
  if [[ $Q_COMPUTER_NAME != "" ]]; then
    COMPUTER_NAME=$Q_COMPUTER_NAME
    secure_hostname_network
  else
    DEBUG "Skipping..."
  fi

  # User
  DEBUG "# Run as User: ${USER_NAME}?"
  read -p "[Enter] to skip. Type to overwrite: " -r Q_USER_NAME
  if [[ $Q_USER_NAME != "" ]]; then
    USER_NAME=$Q_USER_NAME
    WARN "Updated User: ${USER_NAME}"
  fi

  cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass --ask-vault-pass -i inventories/${INVENTORY} plays/provision/${PLAY}.yml -e "home=${HOME} user_name=${USER_NAME} user_group=${USER_GROUP} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"

  
}

if [ $# -eq 0 ]; then
  interactiveArguments
else
  processArguments "$@"
fi

if [[ ${SECURE} == true ]]; then
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

FATAL "Unknown Error. Maybe invalid platform (Only works on Mac or Linux)."
exit 1
