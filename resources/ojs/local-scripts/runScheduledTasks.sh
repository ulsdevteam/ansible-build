#!/bin/sh
#
# Execute runScheduledTasks.php for each PKP application with "scheduled_tasks" configured
#
SEARCHBASE=/var/www/vhosts
PHP=/usr/bin/php
RUNST=tools/runScheduledTasks.php
AUTOSTAGE=plugins/generic/usageStats/scheduledTasksAutoStage.xml
PKPPLN=plugins/generic/pln/xml/scheduledTasks.xml
CROSSREF=plugins/importexport/crossref/scheduledTasks.xml

for i in `grep -isl '^scheduled_tasks *= *on' $SEARCHBASE/*/html/config.inc.php $SEARCHBASE/*/html/ojs/config.inc.php | rev | cut -d/ -f2- | rev`
do
  if [ -f $i/$RUNST ]
  then
    cd $i
    $PHP $RUNST
    if [ -f $AUTOSTAGE ]
    then
      # 2.x
      $PHP $RUNST $AUTOSTAGE
    elif [ -f lib/pkp/$AUTOSTAGE ]
    then
      # 3.x
      $PHP $RUNST lib/pkp/$AUTOSTAGE
    fi
    CONFIG="config.inc.php"
    MYSQLDATABASE=
    MYSQLUSER=
    MYSQLPW=
    if [ -e "$CONFIG" ]
    then
      MYSQLDATABASE=`grep '^name = ' $CONFIG | sed -e 's/name = //'`
      MYSQLPW=`grep '^password = ' $CONFIG | sed -e 's/password = //'`
      MYSQLUSER=`grep '^username = ' $CONFIG | sed -e 's/username = //'`
      if [ "$MYSQLUSER" != ""  -a "$MYSQLPW" != "" -a "$MYSQLDATABASE" != "" ]
      then
        ISENABLED=`echo 'select max(setting_name) from plugin_settings where plugin_name = "plnplugin" and setting_name = "enabled" and setting_value = "1"' | mysql -N -u $MYSQLUSER -p$MYSQLPW -D$MYSQLDATABASE`
        if [ "$ISENABLED" = "enabled" -a -f $PKPPLN ]
        then
          $PHP $RUNST $PKPPLN
        fi
        ISENABLED=`echo 'select max(setting_name) from plugin_settings where plugin_name = "crossrefexportplugin" and setting_name = "automaticRegistration" and setting_value = "1"' | mysql -N -u $MYSQLUSER -p$MYSQLPW -D$MYSQLDATABASE`
        if [ "$ISENABLED" = "automaticRegistration" -a -f $CROSSREF ]
        then
          $PHP $RUNST $CROSSREF
        fi
      fi
    fi
  fi
done

