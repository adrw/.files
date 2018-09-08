# By Andrew Paradi | Source at https://github.com/adrw/.files
#!/usr/bin/env bash

# set up bash to handle errors more aggressively - a "strict mode" of sorts
set -e # give an error if any command finishes with a non-zero exit code
set -u # give an error if we reference unset variables
set -o pipefail # for a pipeline, if any of the commands fail with a non-zero exit code, fail the entire pipeline with that exit code

function status() {
  Reset="$(tput sgr0)"       # Text Reset
  Red="$(tput setaf 1)"          # Red
  Green="$(tput setaf 2)"        # Green
  Blue="$(tput setaf 4)"         # Blue
  div="********************************************************************************"
  if [ "$#" -lt 3 ]; then   # if no name override passed in, take name "ap" if $0 is status, $0 otherwise
    [ $(basename "${0}") = "status" ] && scriptname="ap" || scriptname=$(basename "${0}")
  else
    scriptname="${3}"
  fi
  case "${1}" in
    a)        echo ""; echo "${Blue}<|${scriptname:0:1}${Reset} [ ${2} ] ${div:$((${#2}+9))}" ;;
    b)        echo "${Green}ok: [ ${2} ] ${div:$((${#2}+9))}${Reset}" ;;
    s|status) echo "${Blue}<|${scriptname:0:1}${Reset} [ ${2} ] ${div:$((${#2}+9))}" ;;
    t|title)  echo "${Blue}<|${scriptname}${Reset} [ ${2} ] ${div:$((${#2}+8+${#scriptname}))}" ;;
    e|err)    echo "${Red}fatal: [ ${2} ] ${div:$((${#2}+12))}${Reset}" ;;
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

function run_script {
  exec=$*
  script=$1
  name=$(basename ${script})
  status a "${name}"
  ${exec}
  status b "${name}"
}

function show_help {
  status a "❓  Usage :: .files/bootstrap.sh <opts>"
  cat << EOF
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
EOF
  status e "Learn more at https://github.com/adrw/.files"
  exit 0
}

function secure_hostname_network {
  status a "🔐  Secure network and custom host name"
  read -p "Enter name for your Mac: " MAC_NAME
  echo "  - MAC_NAME ${MAC_NAME}"
  # randomize MAC address
  sudo ifconfig en0 ether $(openssl rand -hex 6 | sed 's%\(..\)%\1:%g; s%.$%%')

  # turn off network interfaces
  networksetup -setairportpower en0 off

  # set computer name (as done via System Preferences → Sharing)
  sudo scutil --set ComputerName "${MAC_NAME}"
  sudo scutil --set HostName "${MAC_NAME}"
  sudo scutil --set LocalHostName "${MAC_NAME}"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$MAC_NAME"

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
  status b "🔐  Host Name: ${MAC_NAME}. Firewall: On."
}

function mac_install_dependencies {
  status a "xcode-select, git, homebrew, ansible"

  if ! xcode-select -p 2> /dev/null; then
    status a "Install xcode-select (Command Line Tools)"
    xcode-select --install
    status b  "Install xcode-select (Command Line Tools)"
  fi

  if [[ ! -x "${HOMEBREW_DIR}/bin/brew" ]]; then
    status a "Install Homebrew"
    mkdir -p ${HOMEBREW_DIR} && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW_DIR
    status b "Install Homebrew"
  fi

  export PATH=${HOMEBREW_DIR}/sbin:${HOMEBREW_DIR}/bin:${PATH}

  if [[ ! -x ${HOMEBREW_DIR}/bin/git ]]; then
    status a "Install Git"
    brew install git
    status b "Install Git"
  fi

  if [[ ! -x ${HOMEBREW_DIR}/bin/ansible ]]; then
    status a "Install Ansible"
    brew install ansible
    status b "Install Ansible"
  fi

  status b "xcode-select, git, homebrew, ansible"
}

function mac_scripts {
  status a "scripts | ${PLAY} @ ${INVENTORY}"
  case "${PLAY}" in
  "mac_core"|"mac_square"|"mac_dev"|"mac_clean")
    run_script ${SCRIPTS}/custom.macos
    run_script ${SCRIPTS}/.macos
    if [[ $(csrutil status) != *enabled* ]]; then
      run_script ${SCRIPTS}/homecall.sh fixmacos
    fi
    ;;
  "mac_etchost_no_animate")
    run_script ${SCRIPTS}/no_animate.macos
    ;;
  *)
    status e "no scripts"
  esac
  status b "scripts | ${PLAY} @ ${INVENTORY}"
}

function mac_bootstrap {
  status a "Bootstrap Script"

  mac_install_dependencies

  status a "git/.files -> ${MAIN_DIR}"
  if [[ ! -d ${MAIN_DIR} ]]; then
    status a "Clone .files"
    git clone https://github.com/adrw/.files.git ${MAIN_DIR}
    status b "Clone .files"
  elif [[ "${TEST}" == false ]]; then
    # TODO Delete headless mode
    status a "Decapitate .files (headless mode)"
    cd ${MAIN_DIR}
    git fetch --all
    git reset --hard origin/master
    git checkout origin/master
    status b "Decapitate .files (headless mode)"
  fi
  status b "git/.files -> ${MAIN_DIR}"

  status a "ansible-playbook | ${PLAY} @ ${INVENTORY}"
  case "${PLAY}" in
  "mac_core"|"mac_square"|"mac_dev"|"mac_clean")
    cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass --ask-vault-pass -i inventories/${INVENTORY} plays/provision/${PLAY}.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  "mac_etchost_no_animate")
    cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass -i inventories/${INVENTORY} plays/provision/${PLAY}.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  "mac_jekyll")
    cd "${MAIN_DIR}/ansible" && ansible-playbook --ask-become-pass -i inventories/${INVENTORY} plays/provision/${PLAY}.yml -e "home=${HOME} user_name=${USER_NAME} homebrew_prefix=${HOMEBREW_DIR} homebrew_install_path=${HOMEBREW_INSTALL_DIR} mas_email=${MAS_EMAIL} mas_password=${MAS_PASSWORD}"
    ;;
  *)
    status e "no matching play for ${PLAY}"
  esac
  status b "ansible-playbook | ${PLAY} @ ${INVENTORY}"

  if [ "${ONLY_ANSIBLE}" = false ]; then
    mac_scripts
  fi

  status a "${MAIN_DIR} git remote https:->git:"
  cd ${MAIN_DIR}
  git remote remove origin
  git remote add origin git@github.com:adrw/.files.git
  status b "${MAIN_DIR} git remote https:->git:"

  sudo -k # remove sudo permissions
  status a "🍺  Fin. Bootstrap Script"
  exit 0
}

function linux_bootstrap {
  status a "Install Linux Base Shell"
  # AP Bash Powerline Theme
  safe_download ~/.ap-bash-powerline.sh https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/bash/files/.ap-bash-powerline.sh
  safe_source ~/.ap-bash-powerline.sh ~/.bashrc

  # AP ZSH Powerline Theme
  safe_download ~/.ap-zsh-powerline.sh https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/zsh/files/.ap-zsh-powerline.sh
  safe_source ~/.ap-zsh-powerline.sh ~/.zshrc

  # AP Aliases
  safe_download ~/.ap-aliases https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/aliases/files/.ap-aliases
  safe_source ~/.ap-aliases ~/.bashrc
  safe_source ~/.ap-aliases ~/.zshrc

  # AP Functions
  safe_download ~/.ap-functions https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/functions/files/.ap-functions
  safe_source ~/.ap-functions ~/.bashrc
  safe_source ~/.ap-functions ~/.zshrc

  # AP .vimrc
  safe_download ~/.vimrc https://raw.githubusercontent.com/adrw/.files/master/ansible/roles/vim/files/.vimrc
  
  echo "curl -s https://raw.githubusercontent.com/adrw/.files/master/bootstrap.sh | bash -s" > .ap-update.sh
  chmod +x .ap-update.sh

  status a "🍺  Fin. Bootstrap Script"
  exit 0
}

bash -c 'figlet -f slant "ADRW .files" 2> /dev/null; echo -n ""'
status t "Welcome to .files bootstrap!"
status s "Andrew Paradi. https://github.com/adrw/.files"

ONLY_ANSIBLE=false                  # -a
MAIN_DIR="${HOME}/.files"             # -d
SCRIPTS="${MAIN_DIR}/scripts"
HOMEBREW_DIR="${HOME}/.homebrew"      # -b
HOMEBREW_INSTALL_DIR="${HOMEBREW_DIR}"
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
    d)  echo "  - MAIN_DIR ${MAIN_DIR} => ${OPTARG}"
        MAIN_DIR=${OPTARG}
        SCRIPTS="${MAIN_DIR}/scripts"
        ;;
    b)  echo "  - HOMEBREW_DIR ${HOMEBREW_DIR} => ${OPTARG}"
        HOMEBREW_DIR=${OPTARG}
        HOMEBREW_INSTALL_DIR="${OPTARG}/Homebrew"
        ;;
    i)  echo "  - INVENTORY ${INVENTORY} => ${OPTARG}"
        INVENTORY=${OPTARG}
        ;;
    l)  echo "  - LINUX => PURE (no ansible)"
        LINUX=true
        ;;
    p)  echo "  - PLAY ${PLAY} => ${OPTARG}"
        PLAY=${OPTARG}
        ;;
    m)  echo "  - MAS_EMAIL ${MAS_EMAIL} => ${OPTARG}"
        MAS_EMAIL=$OPTARG
        ;;
    n)  echo "  - MAS_PASSWORD ${MAS_PASSWORD} => ${OPTARG}"
        MAS_PASSWORD=${OPTARG}
        ;;
    s)  echo "  - Secure network and custom host name"
        SECURE=true
        ;;
    t)  echo "  - Test Environment (Git Head still attached)"
        TEST=true
        ;;
    u)  echo "  - USER ${USER_NAME} => ${OPTARG}"
        USER_NAME=${OPTARG}
        HOME="/Users/${USER_NAME}"
        ;;
    esac
done

shift $((OPTIND-1))
echo "Leftovers: $@"

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

status e "Unknown Error. Maybe invalid platform (Only works on Mac or Linux)."
exit 1
