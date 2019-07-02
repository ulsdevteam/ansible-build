#!/bin/bash
if [ "$#" != "2" ]
then
	echo "Usage: $0 site emailDomain"
	exit 1
fi

CONFIG="/var/www/vhosts/$1/html/config.inc.php"
MYSQLDATABASE=
MYSQLUSER=
MYSQLPW=
if [ ! -e "$CONFIG" ]
then
	CONFIG="/var/www/vhosts/$1/html/ojs/config.inc.php"
fi
if [ -e "$CONFIG" ]
then
	MYSQLDATABASE=`grep '^name = ' $CONFIG | sed -e 's/name = //'`
	MYSQLPW=`grep '^password = ' $CONFIG | sed -e 's/password = //'`
	MYSQLUSER=`grep '^username = ' $CONFIG | sed -e 's/username = //'`
	echo "This is a one way ticket with no backup"
	echo -n "Type 'yes' if you really want to munge the emails for database '$MYSQLDATABASE': "
	read USERCONFIRM
	if [ "$USERCONFIRM" != "yes" ]
	then
		>&2 echo "Aborting"
		exit 1
	fi
	if [ "$MYSQLUSER" != ""  -a "$MYSQLPW" != "" -a "$MYSQLDATABASE" != "" ]
	then
		echo "select concat('update \`', table_schema, '\`.', table_name, ' set ', column_name, ' = concat(replace(', column_name, ', "'"'"@"'"'", "'"'"."'"'"), "'"'"@$2"'"'") where ', column_name, ' like "'"'"%_@_%"'"'"; select row_count() as updates, "'"'"', table_name, '.', column_name, '"'"'" as field;') from information_schema.columns where column_name like '%email' and data_type like '%char' and table_schema = '$MYSQLDATABASE';" | mysql -N -u $MYSQLUSER -p$MYSQLPW -D$MYSQLDATABASE | while read updatestmt
		do
			echo "$updatestmt" | mysql -N -u $MYSQLUSER -p$MYSQLPW -D$MYSQLDATABASE
		done
		echo "select concat('update \`', n.table_schema, '\`.', n.table_name, ' set ', v.column_name, ' = concat(replace(', v.column_name, ', "'"'"@"'"'", "'"'"."'"'"), "'"'"@$2"'"'") where ', n.column_name, ' like "'"'"%email"'"'" and ', v.column_name, ' like "'"'"%_@_%"'"'"; select row_count() as updates, "'"'"', n.table_name, '.', v.column_name, '"'"'" as field;') from information_schema.columns n, information_schema.columns v where n.column_name = 'setting_name' and n.data_type like '%char' and v.column_name = 'setting_value' and v.data_type = 'text' and n.table_schema = v.table_schema and n.table_name = v.table_name and n.table_schema = '$MYSQLDATABASE'" | mysql -N -u $MYSQLUSER -p$MYSQLPW -D$MYSQLDATABASE | while read updatestmt
		do
			echo "$updatestmt" | mysql -N -u $MYSQLUSER -p$MYSQLPW -D$MYSQLDATABASE
		done
	else
		>&2 echo "Site config for $1 not understood"
	fi
else
	>&2 echo "config.inc.php for $1 not found"
fi
