Andrew's .files
===
**Ansible provisioning of macOS and Linux**

Mac
===
1. Reboot with `option` into Recovery parition on a USB
2. Erase `Macintosh HD` and restore AutoDMG generated image to it
3. Enable Filevault and restart
4. Provision with command below in Terminal
```Bash
$ cd ~/; curl -sO https://raw.githubusercontent.com/andrewparadi/.files/master/bootstrap.sh; chmod +x ~/bootstrap.sh; ~/bootstrap.sh -s; rm ~/bootstrap.sh
```
5. Reboot and fin.

**`bootstrap.sh` options**
- `-d` choose main directory for the `.files/`. Default: `${HOME}/.files`
- `-b` homebrew install directory. Default: `${HOME}/.homebrew`. Other: `/usr/local`
- `-i` ansible inventory. Default: `macbox/hosts`
- `-p` ansible playbook. Default: `mac_core`. Other: `mac_dev`.
- `-m` mac app store email
- `-n` mac app store password
- `-s` run security setup, set hostname (prompted to type at runtime), enable firewall
- `-t` use test environment, no git checkout
- `-u` set user name that will be used to set owner for all file operations. Default: me

FAQ / Non-Automated Setup Tasks
---
- Generate SSH keys? Delete `ansible/roles/ssh/defaults/main.yml` and use `ansible-vault create` to make new `main.yml` with following keys
  - `ssh_file` full path to where you want the `id_rsa` file generated (usually `~/.ssh/id_rsa`)
  - `ssh_passphrase` generate with a given passphrase
- Add SSH key to GitHub? `pbcopy < ~/.ssh/id_rsa.pub` -> [GitHub.com/settings/keys](https://github.com/settings/keys)
- `Privoxy` not working? Check that proxy `127.0.0.1:8118` was added to HTTP and HTTPS sections in Airport and Ethernet
- Want to remove `admin` privileges from a user?
  - Find `GeneratedUID` of account with `$ dscl . -read /Users/<username> GeneratedUID`
  - Remove from admin with `$ sudo dscl . -delete /Groups/admin GroupMembers <GeneratedUID>`
- Hide a user profile? [Apple docs](https://support.apple.com/en-us/HT203998)
  - Hide from login screen `sudo dscl . create /Users/hiddenuser IsHidden 1`
  - Hide home directory and share point
    ```Bash
    $ sudo mv /Users/hiddenuser /var/hiddenuser
    $ sudo dscl . -create /Users/hiddenuser NFSHomeDirectory /var/hiddenuser
    $ sudo dscl . -delete "/SharePoints/Hidden User's Public Folder"
    ```
- Syncthing? Installed at `https://127.0.0.1:8384/`
- Auto-launch Syncthing? [Syncthing docs](https://github.com/syncthing/syncthing/tree/master/etc/macosx-launchd)
  1. Find Syncthing in brew folder (usually '~/.homebrew/Cellar/syncthing')
  1. Copy the `syncthing.plist` file to `~/Library/LaunchAgents`.
  1. Log out and in again, or run `launchctl load
   ~/Library/LaunchAgents/syncthing.plist`.

Useful Resources
---
- [Ansible docs](https://docs.ansible.com/ansible/) very thorough spec for all standard Ansible modules and functionality
- [macOS-Security-and-Privacy-Guide](https://github.com/drduh/macOS-Security-and-Privacy-Guide) - [@drduh](https://github.com/drduh) consolidates best practices from enterprise IT and government to secure macOS from many standard threat models
- [mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook) - [@geerlingguy](https://github.com/geerlingguy) one of the best macOS Ansible playbooks I found, he also wrote many great Ansible Roles which you can use in your own playbook too
- [.tmux](https://github.com/gpakosz/.tmux) - [@gpakosz](https://github.com/gpakosz) awesome tmux configuration file for terminal multiplexing (multiple shell instances in the same terminal session)
- [iterm2-solarized](https://gist.github.com/kevin-smets/8568070) - [@kevin-smets](https://github.com/kevin-smets) really nice iTerm2 configuration with a `Dark-Solarized` theme, `oh-my-zsh`, [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions#oh-my-zsh) and [Powerlevel9k](https://github.com/bhilburn/powerlevel9k)
- [dotfiles/.macos](https://github.com/mathiasbynens/dotfiles) - [@mathiasbynens](https://github.com/mathiasbynens) >900 lines of great common sense macOS defaults and configuration that you can easily clone and customize
- [dockutil](https://github.com/kcrawford/dockutil) - [@kcrawford](https://github.com/kcrawford) great shell script for customizing macOS dock items
- [mac-dev-playbook](https://github.com/ricbra/mac-dev-playbook) - [@ricbra](https://github.com/ricbra) another great example (this includes `dockutil`)
- [hosts](https://github.com/StevenBlack/hosts) - [@StevenBlack](https://github.com/StevenBlack) community built lists of undesirable domains that can be blocked using your `/etc/hosts` file
- [macOS-home-call-drop](https://github.com/karek314/macOS-home-call-drop) - [@karek314](https://github.com/karek314) shell script that restricts macOS daemons and agents from "phoning home" to Cupertino
- [AutoDMG](https://github.com/MagerValp/AutoDMG) - [@MagerValp](https://github.com/MagerValp) simply macOS app that builds macOS install images for easy machine imaging
- [CreateUserPkg](https://github.com/MagerValp/CreateUserPkg) - [@MagerValp](https://github.com/MagerValp) macOS app that creates macOS pkg containing configuration for a macOS user account, can be included with an `AutoDMG` image
