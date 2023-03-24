#!/bin/bash
if [ $# -lt 2 ]
then
	echo "Usage: $0 sql site [site] [...]"
	echo "  Run the specified sql command agsint the database for each OJS site, by pathname."
	exit 1
fi

SQL="$1"
for p in "${@:2}"
do
	SITE=`basename $p`
	CONFIG="/var/www/vhosts/$SITE/html/config.inc.php"
	MYSQLDATABASE=
	MYSQLUSER=
	MYSQLPW=
	MUNGETARGET=
	if [ ! -e "$CONFIG" ]
	then
		CONFIG="/var/www/vhosts/$SITE/html/ojs/config.inc.php"
	fi
	if [ -e "$CONFIG" ]
	then
		MYSQLDATABASE=`grep '^name = ' $CONFIG | head -1 | sed -e 's/name = //'`
		MYSQLPW=`grep '^password = ' $CONFIG | head -1 | sed -e 's/password = //'`
		MYSQLUSER=`grep '^username = ' $CONFIG | head -1 | sed -e 's/username = //'`
		if [ "$MYSQLUSER" != ""  -a "$MYSQLPW" != "" -a "$MYSQLDATABASE" != "" ]
		then
			>&2 echo "Query $MYSQLDATABASE for $SITE"
			echo "$SQL" | mysql -N -u $MYSQLUSER -p$MYSQLPW -D$MYSQLDATABASE
		else
			>&2 echo "Site config for $SITE not understood"
		fi
	else
		>&2 echo "config.inc.php for $SITE not found"
	fi
done
