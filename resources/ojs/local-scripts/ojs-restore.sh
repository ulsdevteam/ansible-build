#!/bin/bash

# Restore a specified site from the backup in $BACKUPROOT to $VHOSTROOT
# Warning: Uses sudo

BACKUPROOT=${BACKUPROOT:-/var/local/backup/ojs}
VHOSTROOT="/var/www/vhosts/"

if [ "$#" != "1" ]
then
	echo "Usage: $0 site"
	exit 1
fi

OJSROOT="$VHOSTROOT/$1/html"
MYSQLDATABASE=
MYSQLUSER=
MYSQLPW=
if [ ! -e "$BACKUPROOT/$1" ]
then
	echo "Backup $BACKUPROOT/$1 does not exist"
	exit 1
fi
if [ ! -e "$OJSROOT/config.inc.php" ]
then
	OJSROOT="/var/www/vhosts/$1/html/ojs"
fi
if [ -e "$OJSROOT/config.inc.php" ]
then
	MYSQLDATABASE=`grep -A20 -F '[database]' $OJSROOT/config.inc.php | grep '^name = ' | head -1 | sed -e 's/name = //'`
	MYSQLPW=`grep -A20 -F '[database]' $OJSROOT/config.inc.php | grep '^password = ' | head -1 | sed -e 's/password = //'`
	MYSQLUSER=`grep -A20 -F '[database]' $OJSROOT/config.inc.php | grep '^username = ' | head -1 | sed -e 's/username = //'`
	BACKUPDIR=$BACKUPROOT/$1
	sudo mysql -e 'DROP DATABASE IF EXISTS `'$MYSQLDATABASE'` ; CREATE DATABASE `'$MYSQLDATABASE'` CHARACTER SET utf8 COLLATE utf8_general_ci; GRANT ALL ON `'$MYSQLDATABASE'`.* to '$MYSQLUSER'@localhost IDENTIFIED BY "'$MYSQLPW'";'
	grep -qF ' CHARSET=latin1' $BACKUPDIR/db.sql
	if [ $? = 0 ]
	then
		echo 'Found latin1 in CHARSET; Consider updating to utf8'
	fi
	grep -qF ' ENGINE=MyISAM' $BACKUPDIR/db.sql
	if [ $? = 0 ]
	then
		echo 'Found MyISAM in ENGINE; Consider updating to InnoDB'
	fi
	mysql -u$MYSQLUSER -p$MYSQLPW $MYSQLDATABASE < $BACKUPROOT/db.sql
	echo 'sudo as root to remove files'
	sudo rm -fr $VHOSTROOT/$1/files/*
	sudo rm -fR $OJSROOT/public/*
	echo 'sudo as apache to add files'
	sudo -u apache cp -r $BACKUPDIR/public/* $OJSROOT/public/
	sudo -u apache cp -r $BACKUPDIR/files/* $VHOSTROOT/$1/files/
	cp $BACKUPDIR/config.inc.php $OJSROOT/config.inc.php
else
	echo "Original OJS directory not found for $1"
	exit 1
fi

