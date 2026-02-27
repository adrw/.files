#!/usr/bin/env bash

DAEMONS=()
DAEMONS+=('com.apple.netbiosd') #Netbiosd is microsoft's networking service. used to share files between mac and windows
#DAEMONS+=('com.apple.preferences.timezone.admintool') #Time setting daemon
#DAEMONS+=('com.apple.preferences.timezone.auto') #Time setting daemon
#DAEMONS+=('com.apple.remotepairtool') #Pairing devices remotely
#DAEMONS+=('com.apple.rpmuxd') #daemon for remote debugging of mobile devices.
#DAEMONS+=('com.apple.security.FDERecoveryAgent') #Full Disk Ecnryption - Related to File Vault https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man8/FDERecoveryAgent.8.html
#DAEMONS+=('com.apple.icloud.findmydeviced') #Related to find my mac
#DAEMONS+=('com.apple.findmymacmessenger') #Related to find my mac daemon, propably act on commands sent through FindMyDevice in iCloud
DAEMONS+=('com.apple.familycontrols') #Parent control
#DAEMONS+=('com.apple.findmymac') #Find my mac daemon
#DAEMONS+=('com.apple.AirPlayXPCHelper') #Airplay daemon
DAEMONS+=('com.apple.SubmitDiagInfo') #Feedback - most likely it submits your computer data when click 'About this mac'
DAEMONS+=('com.apple.screensharing') #Screensharing daemon
DAEMONS+=('com.apple.appleseed.fbahelperd') #Related to feedback
#DAEMONS+=('com.apple.apsd') #Apple Push Notification Service (apsd) - it's calling home quite often + used by Facetime and Messages
DAEMONS+=('com.apple.AOSNotificationOSX') #Notifications
#DAEMONS+=('com.apple.FileSyncAgent.sshd') #Mostlikely sshd on this machine
#DAEMONS+=('com.apple.ManagedClient.cloudconfigurationd') #Related to manage current macOS user iCloud
#DAEMONS+=('com.apple.ManagedClient.enroll') #Related to manage current macOS user
#DAEMONS+=('com.apple.ManagedClient') #Related to manage current macOS user
#DAEMONS+=('com.apple.ManagedClient.startup') #Related to manage current macOS user
#DAEMONS+=('com.apple.iCloudStats') #Related to iCloud
#DAEMONS+=('com.apple.locationd') #Propably reading current location
#DAEMONS+=('com.apple.mbicloudsetupd') #iCloud Settings
#DAEMONS+=('com.apple.laterscheduler') #Schedule something?
DAEMONS+=('com.apple.awacsd') #Apple Wide Area Connectivity Service daemon - Back to My Mac Feature
#DAEMONS+=('com.apple.eapolcfg_auth') #perform privileged operations required by certain EAPOLClientConfiguration.h APIs
DAEMONS+=('com.apple.awdd') #Sending out diagnostics & usage
DAEMONS+=('com.apple.CrashReporterSupportHelper') #Crash reporter
#DAEMONS+=('com.apple.trustd') #Propably related to certificates

AGENTS=()
#AGENTS+=('com.apple.photoanalysisd') #Apple AI to analyse photos stored in Photos.app, most likely to match faces and scenery but it happens to make requests to Apple during process, i have not checked what are those requestes i have just blocked it with Little Snitch
#AGENTS+=('com.apple.telephonyutilities.callservicesd') #Handling phone and facetime calls
#AGENTS+=('com.apple.AirPlayUIAgent') #Related Airport
#AGENTS+=('com.apple.AirPortBaseStationAgent') #Related Airport
#AGENTS+=('com.apple.CalendarAgent') #Calendar events related to iCloud
#AGENTS+=('com.apple.iCloudUserNotifications') #iCloud notifications, like reminders
#AGENTS+=('com.apple.familycircled') #Family notifications, like reminders
#AGENTS+=('com.apple.familycontrols.useragent') #Family notifications, like reminders
#AGENTS+=('com.apple.familynotificationd') #Family notifications, like reminders
#AGENTS+=('com.apple.gamed') #GameCenter
#AGENTS+=('com.apple.icloud.findmydeviced.findmydevice-user-agent') #Find my device ?
#AGENTS+=('com.apple.icloud.fmfd') #Find my device ?
#AGENTS+=('com.apple.imagent') #Facetime & Messages
AGENTS+=('com.apple.cloudfamilyrestrictionsd-mac') #iCloud Family restrictions
AGENTS+=('com.apple.cloudpaird') #Related to iCloud
AGENTS+=('com.apple.cloudphotosd') #Propably syncing your photos to icloud
AGENTS+=('com.apple.DictationIM') #Dictation
AGENTS+=('com.apple.assistant_service') #Siri
#AGENTS+=('com.apple.CallHistorySyncHelper') #Related to call history syncing (iCloud)
#AGENTS+=('com.apple.CallHistoryPluginHelper') #Related to call history (iCloud)
#AGENTS+=('com.apple.AOSPushRelay') # Related to iCloud https://github.com/fix-macosx/yosemite-phone-home/blob/master/icloud-user-r0/System/Library/PrivateFrameworks/AOSKit.framework/Versions/A/Helpers/AOSPushRelay.app/Contents/MacOS/AOSPushRelay/20141019T072634Z-auser-%5B172.16.174.146%5D:49560-%5B17.110.240.83%5D:443.log
#AGENTS+=('com.apple.IMLoggingAgent') #IMFoundation.framework - Not sure about this one, maybe used to log in to computer on start
#AGENTS+=('com.apple.geodMachServiceBridge') #Located in GeoServices.framework, related to locations maybe used for maps, maybe as well for things like find my mac, or just syping
#AGENTS+=('com.apple.syncdefaultsd') ##Propably related to syncing keychain
#AGENTS+=('com.apple.security.cloudkeychainproxy3') #Propably related to syncing keychain to icloud
#AGENTS+=('com.apple.security.idskeychainsyncingproxy') #Most likely also related to keychain - IDSKeychainSyncingProxy.bundle
#AGENTS+=('com.apple.security.keychain-circle-notification') #Related to keychain
#AGENTS+=('com.apple.sharingd') #Airdrop, Remote Disks, Shared Directories, Handoff
AGENTS+=('com.apple.appleseed.seedusaged') #Feedback assistant
#AGENTS+=('com.apple.cloudd') #Related to sync data to iCloud, most likely used by iMessage,Mail,iCloud drive, etc...
#AGENTS+=('com.apple.assistant') #Keychain
AGENTS+=('com.apple.parentalcontrols.check') #Related to parental control
AGENTS+=('com.apple.parsecd') #Used by spotlight and/or siri, propably some suggestions - CoreParsec.framework
#AGENTS+=('com.apple.identityservicesd') #Used to auth some apps, as well used by iCloud
#AGENTS+=('com.apple.bird') #Part of iCloud
AGENTS+=('com.apple.rtcreportingd') #Related to Home Sharing, most likely it checks if device is auth for home sharing + Facetime
AGENTS+=('com.apple.SafariCloudHistoryPushAgent') #Good one, sending out your browsing history... :)
AGENTS+=('com.apple.safaridavclient') #Sending bookmarks to iCloud, even if you disable it may send your bookmarks to Apple
AGENTS+=('com.apple.SafariNotificationAgent') #Notifications in Safari


help_msg(){
  echo ""
  echo "macOS home call dropper by karek314"
  echo "version 1.0"
  echo ""
  echo "Available commands"
  echo "fixmacos - fix your macOS to stop/limit invade your privacy"
  echo "restore - restore to default settings"
  echo "help - help message"
}


fix_spotlight(){
  #Global System Preferences
  TMP=$(plutil -convert xml1 -o - ~/Library/Preferences/com.apple.Spotlight.plist)
  TMP=$(tr -d '\040\011\012\015' <<< $TMP)
  TMP=$(awk -F "<key>orderedItems</key><array>|</array>" '{print $2}' <<< $TMP)
  #echo "Current Settings"
  #echo $TMP
  TMP=$(sed 's|<dict><key>enabled</key><true/><key>name</key><string>MENU_SPOTLIGHT_SUGGESTIONS</string></dict>|<dict><key>enabled</key><false/><key>name</key><string>MENU_SPOTLIGHT_SUGGESTIONS</string></dict>|g' <<< $TMP)
  TMP=$(sed 's|<dict><key>enabled</key><true/><key>name</key><string>MENU_DEFINITION</string></dict>|<dict><key>enabled</key><false/><key>name</key><string>MENU_DEFINITION</string></dict>|g' <<< $TMP)
  TMP=$(sed 's|<dict><key>enabled</key><true/><key>name</key><string>MENU_CONVERSION</string></dict>|<dict><key>enabled</key><false/><key>name</key><string>MENU_CONVERSION</string></dict>|g' <<< $TMP)
  #echo "New Settings"
  #echo $TMP
  defaults delete com.apple.Spotlight.plist orderedItems
  defaults write com.apple.Spotlight.plist orderedItems "<array>$TMP</array>"

  # Safari Preferences
  defaults write com.apple.Safari.plist UniversalSearchEnabled -bool NO
  defaults write com.apple.Safari.plist SuppressSearchSuggestions -bool YES
  defaults write com.apple.Safari.plist WebsiteSpecificSearchEnabled -bool NO
}


start(){
  echo ""
  fix_spotlight
  echo "System Spotlight & Suggestions Fixed"
  echo ""
  for agent in "${AGENTS[@]}"
  do
    sudo launchctl unload -w /System/Library/LaunchAgents/${agent}.plist
    launchctl unload -w /System/Library/LaunchAgents/${agent}.plist
    echo "Agent ${agent} disabled"
  done
  echo ""
  echo "Specified agents has been disabled"
  echo ""
  for daemon in "${DAEMONS[@]}"
  do
    sudo launchctl unload -w /System/Library/LaunchDaemons/${daemon}.plist
    launchctl unload -w /System/Library/LaunchDaemons/${daemon}.plist
    echo "Daemon ${daemon} disabled"
  done
  echo ""
  echo "Specified daemons has been disabled"
  echo ""
  echo "Spotlight and safari suggestions has been fixed and your keystorokes are no longer sent out to apple!"
  echo ""
  echo "!!!RESTART YOUR COMPUTER NOW TO APPLY CHANGES!!!"
  echo ""
}


restore(){
  for agent in "${AGENTS[@]}"
  do
    sudo launchctl load -w /System/Library/LaunchAgents/${agent}.plist
    launchctl load -w /System/Library/LaunchAgents/${agent}.plist
    echo "Agent ${agent} enabled"
  done
  echo ""
  echo "Specified agents has been enabled"
  echo ""
  for daemon in "${DAEMONS[@]}"
  do
    sudo launchctl load -w /System/Library/LaunchDaemons/${daemon}.plist
    launchctl load -w /System/Library/LaunchDaemons/${daemon}.plist
    echo "Daemon ${daemon} enabled"
  done
  echo ""
  echo "Specified daemons has been enabled"
  echo ""
  echo "RESTART YOUR COMPUTER NOW TO APPLY CHANGES"
  echo ""
}


case $1 in
"fixmacos")
  start
  ;;
"help")
  help_msg
  ;;
"restore")
  restore
  ;;
*)
  help_msg
  ;;
esac
