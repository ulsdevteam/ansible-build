#!/bin/bash

# Upgrade a specified site to a specified version
# Warning: Uses sudo

VHOSTROOT="/var/www/vhosts"
APACHECONF="/etc/httpd/conf.d/vhosts"

if [ "$#" != "2" ]
then
        echo "Usage: $0 site version"
	echo "	site: folder name in "$VHOSTROOT
	echo "	version: tgz file path or url"
        exit 1
fi

OJSROOT="$VHOSTROOT/$1/html"
if [ ! -e "$OJSROOT/config.inc.php" ]
then
        OJSROOT="/var/www/vhosts/$1/html/ojs"
fi
if [ -e "$OJSROOT/config.inc.php" ]
then
	if [ -f $2 ]
	then
		RELEASE=$2
	else
		RELEASE=`mktemp`
		wget -O $RELEASE $2		
	fi
	tar -tzf $RELEASE | grep config.TEMPLATE.inc.php
	if [ "$?" == "0" ]
	then
		APACHECONFFILE=$APACHECONF/${1%/}.conf
		mv ${APACHECONFFILE} ${APACHECONFFILE}.disabled
		echo 'sudo as root to graceful apache'
		sudo apachectl graceful
		mv ${APACHECONFFILE}.disabled ${APACHECONFFILE}
		if [ -e ${OJSROOT}.old ]
		then
			echo 'sudo as root to remove old directory'
			sudo rm -fR ${OJSROOT}.old
		fi
		mv $OJSROOT ${OJSROOT}.old
		mkdir $OJSROOT
		echo 'sudo as root to untar files'
		sudo tar -xzf $RELEASE -C $OJSROOT
		echo 'sudo as apache to copy files'
		sudo -u apache cp -r ${OJSROOT}.old/public/* $OJSROOT/public/
		cp $OJSROOT/config.TEMPLATE.inc.php $OJSROOT/config.new.php
		diff ${OJSROOT}.old/config.TEMPLATE.inc.php ${OJSROOT}.old/config.inc.php | patch $OJSROOT/config.new.php
		mv $OJSROOT/config.new.php $OJSROOT/config.inc.php
		echo 'sudo as apache to check upgrade'
		sudo -u apache php $OJSROOT/tools/upgrade.php check
		echo diff ${OJSROOT}.old/config.TEMPLATE.inc.php ${OJSROOT}/config.TEMPLATE.inc.php
		echo 'Type "yes" when ready for upgrade...'
		read DOUPGRADE
		if [ "$DOUPGRADE" == "yes" ]
		then
			OUTFILE=`mktemp`
			sudo -u apache php $OJSROOT/tools/upgrade.php upgrade 2>&1 | tee $OUTFILE
			echo 'Recorded as '$OUTFILE
			echo 'sudo as root to restorecon'
			sudo restorecon -R $OJSROOT
			sudo apachectl graceful
			sudo rm -fR ${OJSROOT}.old
		else
			echo "Aborting! You may want to:"
			echo "  sudo -u apache php $OJSROOT/tools/upgrade.php upgrade"
			echo "  sudo restorecon -R $OJSROOT"
			echo "  sudo apachectl graceful"
			echo "  sudo rm -fR ${OJSROOT}.old"
			echo "OR..."
			echo "  mv ${OJSROOT}.old $OJSROOT"
			echo "  sudo apachectl graceful"
			exit 2
		fi
	else
		echo "Release doesn't look sane"
		exit 1
	fi
else
	echo "Original OJS directory not found for $1"
	exit 1
fi

