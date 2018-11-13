Mac Terminal Syntax

#Mac Terminal Commands
##Force Empty Trash
rm -rf ~/.Trash/\*
or option click empty

##Empty DNS Cache
sudo killall -HUP mDNSResponder

##Empty DNS Cache
sudo killall -HUP mDNSResponder

##Change Screenshot Location
Launch Terminal and use the following syntax:

defaults write com.apple.screencapture location /path/

For example, if I want to have the screenshots appear in my Pictures folder, I would use:

defaults write com.apple.screencapture location ~/Pictures/

To have the changes take effect, you then must type:

killall SystemUIServer

##Compact Sparce Bundle Disk Image
hdiutil compact my.sparseimage -batteryallowed

##Toggle Hidden Files/Folders
defaults write com.apple.Finder AppleShowAllFiles YES

##Toggle Hidden Library Folder
chflags nohidden ~/Library/

##Reset Sound Card
sudo kill -9 `ps ax|grep 'coreaudio[a-z]' | awk '{print $1}'`

##Eject Disc
drutil tray eject

##Create Recently Used Dock Item
defaults write com.apple.dock persistent-others -array-add '{ "tile-data" = { "list-type" = 1; }; "tile-type" = "recents-tile"; }'; killall Dock

##Add Dashboard Widgets to the Desktop
defaults write com.apple.dashboard devmode YES

#Only show open apps in dock
defaults write com.apple.dock static-only -bool TRUE; killall
Reverse: defaults write com.apple.dock static-only -bool FALSE; killall

http://www.techradar.com/news/computing/apple/top-25-os-x-terminal-commands-696443

You can create a new administrator account by restarting the Setup Assistant:

1.  Boot into Single User Mode ⌘ + S.
2.  Mount the drive by typing /sbin/mount -uw / then enter.
3.  Remove the Apple Setup Done file by typing rm /var/db/.AppleSetupDone then ↩ enter.
4.  Reboot by typing reboot then ↩ enter.
5.  Complete the setup process, creating a new admin account.
