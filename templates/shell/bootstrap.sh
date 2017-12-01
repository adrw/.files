# By Andrew Paradi | Source at https://github.com/andrewparadi/.files
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

function show_help {
  status a "❓  Usage :: .files/bootstrap.sh {opts}"
  echo "Options |   Description                       |   Default (or alternate) Values"
  echo "${div}"
  echo "-h      |   Show help menu                    |                         "
  err "Learn more at https://github.com/andrewparadi/.files"
  exit 0
}

function mac_bootstrap {
  status a "Bootstrap Script"

  if [[ ! -x $HOMEBREW_DIR/bin/ansible ]]; then
    status a "Install Ansible"
    brew install ansible
    status b "Install Ansible"
  fi

  status b "xcode-select, git, homebrew, ansible"
  status a "🍺  Fin. Bootstrap Script"
  exit 0
}

function linux_bootstrap {
  status a "Install Linux Base Shell"
  # Bash Powerline Theme
  safe_download ~/.bash-powerline.sh https://raw.githubusercontent.com/riobard/bash-powerline/master/bash-powerline.sh
  safe_source ~/.bash-powerline.sh ~/.bashrc

  status a "🍺  Fin. Bootstrap Script"
  exit 0
}

status t "Welcome to .files bootstrap!"
status s "Andrew Paradi. https://github.com/andrewparadi/.files"

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
