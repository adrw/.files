#!/usr/bin/env bash

set -e

if [[ ! -x /usr/bin/gcc ]]; then
  xcode-select --install
fi

if [[ ! -x ~/.homebrew/bin/brew ]]; then
  mkdir -p ~/.homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C ~/.homebrew
fi

export PATH=$PATH:~/.homebrew/sbin:~/.homebrew/bin

if [[ ! -x ~/.homebrew/bin/git ]]; then
  brew install git
fi

if [[ ! -x ~/.homebrew/bin/ansible ]]; then
  brew install ansible
fi

cd ~/.files/ansible && ansible-playbook --ask-sudo-pass -i inventories/macbox/hosts plays/provision/mac_core.yml -e "home=/Users/me mas_email= mas_password="
