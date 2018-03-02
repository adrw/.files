Andrew's .files
===
**Ansible provisioning of macOS and Linux with security in mind**

Linux
===
1. Installs .ap-aliases, .ap-functions, bash & zsh powerline themes
```Bash
$ curl -s https://raw.githubusercontent.com/andrewparadi/.files/master/bootstrap.sh | bash -s
```
2. fin.

Mac
===
1. Reboot with `option` into Recovery parition on a USB
2. Erase `Macintosh HD` and restore AutoDMG generated image to it
3. Enable Filevault and restart
4. Provision with command below in Terminal (add any other option flags before running)
```Bash
$ cd ${HOME}/; curl -sO https://raw.githubusercontent.com/andrewparadi/.files/master/bootstrap.sh; chmod +x ${HOME}/bootstrap.sh; ${HOME}/bootstrap.sh -s; rm ${HOME}/bootstrap.sh
```
5. Reboot (sometimes required) and fin.

**`bootstrap.sh` options**
- `-b` homebrew install directory. Default: `${HOME}/.homebrew`. Other: `/usr/local`
- `-d` choose main directory for the `.files/`. Default: `${HOME}/.files`
- `-h` show help menu
- `-i` ansible inventory. Default: `macbox/hosts`
- `-l` install basic Linux (.ap-aliases, .ap-functions, bash & zsh powerline themes)
- `-m` mac app store email
- `-n` mac app store password
- `-p` ansible playbook to run. Default: `mac_core`. Other: `mac_dev`, `mac_jekyll`, `mac_etchost_no_animate`
- `-s` run security setup, set hostname (prompted to type at runtime), enable firewall
- `-t` use test environment, no git checkout
- `-u` set user name that will be used to set owner for all file operations. Default: `me`

Included Playbooks
---
Change which is run with  `-p {play}` flag in the `bootstrap.sh` script
- `mac_core` my full setup on my personal Mac
- `mac_dev` entire dev environment suitable for work machine (doesn't include any media or photo software)
- `mac_jekyll` minimum requirements to [get-started-with-jekyll](https://github.com/andrewparadi/get-started-with-jekyll)
- `mac_etchost_no_animate` only install /etc/hosts domain blocking and disable Mac animations


FAQ / Non-Automated Setup Tasks
---
- Enable `System Integrity Protection`
  - Check status with `csrutil status`
  - Reboot into Recovery OS: reboot holding Cmd+R
  - In Utilities/Terminal, enable with `csrutil enable`
- Generate SSH keys? Delete `ansible/roles/ssh/defaults/main.yml` and use `ansible-vault create` to make new `defaults/main.yml` with following declared string:
  - `ssh_passphrase` generate id_rsa with a given passphrase then required on every id_rsa use
  - (Optional) `id_rsa: "{ full path }"` full path to where you want the `id_rsa` file generated (usually `~/.ssh/id_rsa`). Optional since it is in mac_core.yml by default for use in other roles.
  - Want to change the file later? `ansible-vault edit ansible/roles/ssh/defaults/main.yml`
- Add SSH key to GitHub? `pbcopy < ~/.ssh/id_rsa.pub` -> [GitHub.com/settings/keys](https://github.com/settings/keys)
- `Privoxy` not working? Check that proxy `127.0.0.1:8118` was added to HTTP and HTTPS sections in Airport and Ethernet
- Want to remove `admin` privileges from a user?
  - Use function `chmod_admin {username}` found in `.ap-functions` which safely implements the steps below. 
  - Reversible in System Preferences / Users by logging in with `admin` account and adding privileges back to another user.
  1. Find `GeneratedUID` of account with `$ dscl . -read /Users/<username> GeneratedUID`
  2. Remove from admin with `$ sudo dscl . -delete /Groups/admin GroupMembers <GeneratedUID>`
- Hide a user profile? [Apple docs](https://support.apple.com/en-us/HT203998)
  - Use function `mv_user` found in `.ap-functions` which safely implements the steps below.
  - Calling function again on a hidden user, restores user to both login and Finder.
  1. Hide from login screen `$ sudo dscl . create /Users/hiddenuser IsHidden 1`
  2. Hide home directory and share point
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

Resources
---
- [Ansible docs](https://docs.ansible.com/ansible/) very thorough spec for all standard Ansible modules and functionality
- [macOS-Security-and-Privacy-Guide](https://github.com/drduh/macOS-Security-and-Privacy-Guide) - [@drduh](https://github.com/drduh) consolidates best practices from enterprise IT and government to secure macOS from many standard threat models
- [SpoofMAC](https://github.com/feross/SpoofMAC) - [@feross](https://github.com/feross) Python and nodeJS script for new randomized MAC address each boot to reduce tracking of your computer across networks. Find in `ansible/roles/spoof-mac`.
- [mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook) - [@geerlingguy](https://github.com/geerlingguy) one of the best macOS Ansible playbooks I found, he also wrote many Ansible Roles which you can use in your own playbook too
- [.tmux](https://github.com/gpakosz/.tmux) - [@gpakosz](https://github.com/gpakosz) awesome tmux configuration file for terminal multiplexing (multiple shell instances in the same terminal session)
- [antibody](https://github.com/getantibody/antibody) - [@caarlos0](https://github.com/caarlos0) Faster version of `Antigen` zsh plugin manager. Well worth switching too after feeling the lag too often of `oh-my-zsh`
- [Bash](https://github.com/riobard/bash-powerline) & [ZSH](https://github.com/riobard/zsh-powerline) Powerline Themes - [@riobard](https://github.com/riobard) Fast Powerline themes with Git support written in Bash and ZSH
- [iterm2-solarized](https://gist.github.com/kevin-smets/8568070) - [@kevin-smets](https://github.com/kevin-smets) really nice iTerm2 configuration with a `Dark-Solarized` theme, `oh-my-zsh`, [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions#oh-my-zsh) and [Powerlevel9k](https://github.com/bhilburn/powerlevel9k)
- [dotfiles/.macos](https://github.com/mathiasbynens/dotfiles) - [@mathiasbynens](https://github.com/mathiasbynens) >900 lines of common sense macOS defaults and configuration that you can easily clone and customize
- [dockutil](https://github.com/kcrawford/dockutil) - [@kcrawford](https://github.com/kcrawford) shell script for customizing macOS dock items
- [mac-dev-playbook](https://github.com/ricbra/mac-dev-playbook) - [@ricbra](https://github.com/ricbra) another example (this includes `dockutil`)
- [hosts](https://github.com/StevenBlack/hosts) - [@StevenBlack](https://github.com/StevenBlack) community built lists of undesirable domains that can be blocked using your `/etc/hosts` file. Find in `ansible/roles/etchosts`.
- [macOS-home-call-drop](https://github.com/karek314/macOS-home-call-drop) - [@karek314](https://github.com/karek314) shell script that restricts macOS daemons and agents from "phoning home" to Cupertino
- [AutoDMG](https://github.com/MagerValp/AutoDMG) - [@MagerValp](https://github.com/MagerValp) simply macOS app that builds macOS install images for easy machine imaging
- [CreateUserPkg](https://github.com/MagerValp/CreateUserPkg) - [@MagerValp](https://github.com/MagerValp) macOS app that creates macOS pkg containing configuration for a macOS user account, can be included with an `AutoDMG` image
