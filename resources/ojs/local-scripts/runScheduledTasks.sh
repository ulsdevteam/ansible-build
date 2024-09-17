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
DOAJ=plugins/importexport/doaj/scheduledTasks.xml

for i in `grep -isl '^scheduled_tasks *= *on' $SEARCHBASE/*/html/config.inc.php $SEARCHBASE/*/html/ojs/config.inc.php | rev | cut -d/ -f2- | rev`
do
  if [ -f $i/$RUNST ]
  then
    cd $i
    $PHP $RUNST
    if [ -f $AUTOSTAGE ]
    then
      # 2.x, 3.1.2+
      $PHP $RUNST $AUTOSTAGE
    elif [ -f lib/pkp/$AUTOSTAGE ]
    then
      # 3.0 - 3.1.1
      $PHP $RUNST lib/pkp/$AUTOSTAGE
    fi
    CONFIG="config.inc.php"
    MYSQLDATABASE=
    MYSQLUSER=
    MYSQLPW=
    if [ -e "$CONFIG" ]
    then
      MYSQLDATABASE=`grep -A20 -F '[database]' $CONFIG | grep '^name = ' | head -1 | sed -e 's/name = //'`
      MYSQLPW=`grep -A20 -F '[database]' $CONFIG | grep '^password = ' | head -1 | sed -e 's/password = //'`
      MYSQLUSER=`grep -A20 -F '[database]' $CONFIG | grep '^username = ' | head -1 | sed -e 's/username = //'`
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
        ISENABLED=`echo 'select max(setting_name) from plugin_settings where plugin_name = "doajexportplugin" and setting_name = "automaticRegistration" and setting_value = "1"' | mysql -N -u $MYSQLUSER -p$MYSQLPW -D$MYSQLDATABASE`
        if [ "$ISENABLED" = "automaticRegistration" -a -f $DOAJ ]
        then
          $PHP $RUNST $DOAJ
        fi
      fi
    fi
  fi
done

