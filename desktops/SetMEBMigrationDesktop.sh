#!/bin/sh


# Bare bones script to install the latest Installomator from Github.
# If we detect that Installomator is already installed, the script will use
# Installomator to check for new versions. If you don't want that to happen,
# Just remove the last else clause.
#
# Feel free to add logging routines, and/or change the osascript error message.
# Script provided as is.
#
# PS. If the shebang is missing at the top of this script, it means
# You set the shell option to "None" in the Mate.

if [[ "$(whoami)" != "root" ]]; then
    # not running as root
    echo "not running as root, exiting"
    exit 1
fi

function runAsUser() {
	currentUser=`stat -f "%Su" /dev/console`
	if [ $currentUser != "loginwindow" ] && [ $currentUser != "_mbsetupuser" ] ; then
		currentUserID=$( id -u "$currentUser" )
		launchctl asuser "$currentUserID" sudo -u "$currentUser" "$@"
		#echo "Current user is: $currentUser" 
	else
		echo "no user logged in"
	fi
}

installomatorURL=$(curl -sfL "https://api.github.com/repos/Installomator/Installomator/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
expectedInstallomatorTeamID="JME5BW3F3R"

if [ ! -e "/usr/local/Installomator/Installomator.sh" ]; then
	workDirectory=$( /usr/local/Installomator/ "$0" )
	tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
	/usr/bin/curl --location --silent "$installomatorURL" -o "$tempDirectory/installomator.pkg"
	teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/installomator.pkg" 2>&1 | awk '/origin=/ { print $NF }' | tr -d '()')
	if [[ "$expectedInstallomatorTeamID" == "$teamID" ]]; then
		/usr/sbin/installer -pkg "$tempDirectory/installomator.pkg" -target /
		sleep 2
	else
		# Use Apple Script to display an error if Team ID does not match the expected
		osascript -e 'display dialog "Sorry, but there was a problem installing Installomator, The Team ID Does not match the expected. Please notify IT of this issue" with title "Error!" buttons {"Close"} with icon caution'
		exit 1
	fi

	/bin/rm -Rf "$tempDirectory"

else
	/usr/local/Installomator/Installomator.sh installomator DEBUG=0 NOTIFY=silent
fi
/usr/local/Installomator/Installomator.sh desktoppr DEBUG=0

sleep 2

runAsUser desktoppr https://raw.githubusercontent.com/KullanderAB/graphics/refs/heads/main/desktops/KIMEBJamf.png
