Image macOS
---

See [`drduh macOS Security and Privacy Guide`](https://github.com/drduh/macOS-Security-and-Privacy-Guide) for more details.

1. Set firmware password. `sudo firmwarepasswd -setpasswd -setmode command`.
1. Build current [AutoDMG](https://github.com/MagerValp/AutoDMG) image including downloaded MacOS installer,  [user](https://magervalp.github.io/CreateUserPkg/), and [custom packages](./autodmg-custom.sparsebundle).
1. Make bootable USB. Erase a USB, *restore* .dmg image to *unmounted* USB partition.
1. On Mac, hold `option` down on restart, then choose the USB Recovery partition.
1. Use Disk Utility to restore USB Macintosh HD back to Mac hard drive Macintosh HD.
1. Restart into Mac, create temp account, don't agree to location, siri, or diagnostics
1. Once through Mac setup flow and on desktop, logout of temp account, login to pre-made admin account, and delete temp account. Continue setup and install with admin account, use other for every day use. 

Setup
---
1. Change system `ComputerName` and `LocalHostName` to remove personal information

  ```
  $ sudo scutil --set ComputerName mbp

  $ sudo scutil --set LocalHostName mbp
  ```

1. Manually seed entropy with random letters then `crtl-d` using `cat > /dev/random`
1. Enable FileVault through GUI or `sudo fdesetup enable`
1. If physical security a potential threat, consider enforcing eviction of FileVault keys when hibernating or sleeping with the following (I haven't done this)

  ```
  $ sudo pmset -a destroyfvkeyonstandby 1
  $ sudo pmset -a hibernatemode 25

  $ sudo pmset -a powernap 0
  $ sudo pmset -a standby 0
  $ sudo pmset -a standbydelay 0
  $ sudo pmset -a autopoweroff 0
  ```

Firewall
---
1. Enable firewall, logging, and stealth mode (doesn't respond to ICMP ping requests or closed TCP/UDP ports)
  ```
  $ sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  $ sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
  $ sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
  ```
1. Stop both built-in and download software from being automatically whitelisted
  ```
  $ sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off

  $ sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off
  ```
1. Third party firewalls
  - [Little Snitch](https://www.obdev.at/products/littlesnitch/index.html)
  - [Hands Off](https://www.oneperiodic.com/products/handsoff/)
  - [Radio Silence](https://radiosilenceapp.com/)
  - [Security Growler](https://pirate.github.io/security-growler/)


No More Phone Home
---
1. Disable `Spotlight Suggestions` and `Allow Spotlight Suggestions in Look up` in `Settings/Spotlight`
1. Disable `Include Safari Suggestions` in `Safari / Preferences / Search`
1. Consider
  - `homecall.sh` script from [macOS-home-call-drop](https://github.com/karek314/macOS-home-call-drop)
  - [fix-macosx.com](https://fix-macosx.com/) for more resources

Homebrew
---
1. Install Command Line Tools, simply type `git` to prompt or use `xcode-select --install`
1. Use [`main.sh`](../main.sh) script to install
  - [`oh-my-zsh`](http://ohmyz.sh/) as default shell
  - [`mac-defaults.sh`](./scripts/mac-defaults.sh) to change Mac settings (show all files, increase keyboard repeate rate...)
  - [`copy-dotfiles.sh`](./scripts/copy-dotfiles.sh) to move `.vimrc` 
  - [Homebrew](https://brew.sh/) into `~/homebrew` folder to maintain security of `/usr/local` [(more)](https://github.com/Homebrew/brew/blob/master/docs/Installation.md#installation)
  - [`install.sh`](./scripts/install.sh) install dev tools, apps through brew cask, and apps through mac app store

Generate SSH Keys
---
1. `ssh-keygen -t rsa -b 4096 -C "me@andrewparadi.com"`
1. `pbcopy < ~/.ssh/id_rsa.pub` save to clipboard and then to GitHub account

DNS
---
1. Append consolidated host file for broad low level blocking of ad and malware networks






