#!/bin/bash

# Backup one or more OJS installations from $VHOSTROOT to $BACKUPROOT, overwriting the last backup
BACKUPROOT=/var/local/backup/ojs
VHOSTROOT="/var/www/vhosts"

if [ "$#" -gt "1" ]
then
	>&2 echo "Usage: $0 [site]"
	exit 1
fi

if [ "$1" != "" ]
then
	OJSDIRS=$VHOSTROOT/$1
else
	OJSDIRS=$VHOSTROOT/*
fi

for OJSSITE in $OJSDIRS
do
	OJSROOT="$OJSSITE/html"
	MYSQLDATABASE=
	MYSQLUSER=
	MYSQLPW=
	if [ ! -e "$OJSROOT/config.inc.php" ]
	then
		OJSROOT="$OJSSITE/html/ojs"
	fi
	if [ -e "$OJSROOT/config.inc.php" ]
	then
		MYSQLDATABASE=`grep -A20 -F '[database]' $OJSROOT/config.inc.php | grep '^name = ' | head -1 | sed -e 's/name = //'`
		MYSQLPW=`grep -A20 -F '[database]' $OJSROOT/config.inc.php | grep '^password = ' | head -1 | sed -e 's/password = //'`
		MYSQLUSER=`grep -A20 -F '[database]' $OJSROOT/config.inc.php | grep '^username = ' | head -1 | sed -e 's/username = //'`
		BACKUPDIR=$BACKUPROOT/`basename $OJSSITE`
		if [ ! -e $BACKUPDIR ]
		then
			mkdir $BACKUPDIR
		fi
		rsync -a --delete $OJSSITE/files/ $BACKUPDIR/files/
		rsync -a --delete $OJSROOT/public/ $BACKUPDIR/public/
		mysqldump -u$MYSQLUSER -p$MYSQLPW $MYSQLDATABASE --result-file=$BACKUPDIR/db.sql
		rsync -a --delete $OJSSITE/files/ $BACKUPDIR/files/
		rsync -a --delete $OJSROOT/public/ $BACKUPDIR/public/
		date '+%Y-%m-%d-%H-%M-%S' > $BACKUPDIR/timestamp.txt
		cp $OJSROOT/config.inc.php $OJSROOT/config.TEMPLATE.inc.php $BACKUPDIR
	fi
	date '+%Y-%m-%d-%H-%M-%S' > $BACKUPROOT/timestamp.txt
done
