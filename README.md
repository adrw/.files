Andrew's .files
---
**Ansible provisioning of macOS and Linux**
Mac
1. Reboot with `option` into Recovery parition on a USB
2. Erase `Macintosh HD` and restore AutoDMG generated image to it
3. Enable Filevault and restart
4. Provision with command below in Terminal
```Bash
cd ~/; curl -sO https://raw.githubusercontent.com/andrewparadi/.files/master/bootstrap.sh; chmod +x ~/bootstrap.sh; ~/bootstrap.sh -s; rm ~/bootstrap.sh
```
5. Reboot and fin.
