Andrew's .files
---
**Ansible provisioning of macOS and Linux**
Mac
1. Reboot with `option` into Recovery parition on a USB
2. Erase `Macintosh HD` and restore AutoDMG generated image to it
3. Enable Filevault and restart
4. Provision with command below in Terminal
```Bash
$ cd ~/; curl -sO https://raw.githubusercontent.com/andrewparadi/.files/master/bootstrap.sh; chmod +x ~/bootstrap.sh; ~/bootstrap.sh -s; rm ~/bootstrap.sh
```
5. Reboot and fin.

Other Steps
---
- `Privoxy` not working? Check that proxy `127.0.0.1:8118` was added to HTTP and HTTPS sections in Airport and Ethernet
- Want to remove `admin` privileges from a user?
  - Find `GeneratedUID` of account with `$ dscl . -read /Users/<username> GeneratedUID`
  - Remove from admin with `$ sudo dscl . -delete /Groups/admin GroupMembers <GeneratedUID>`
