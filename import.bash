#!/bin/bash
. $HOME/.bash_profile
#
DB_NAME=mttestdb
DATA_PRO_PATH=/db2/backup/aixmigration/sample
DATA_LOG_PATH=$DATA_PRO_PATH/logs
DATA_LOG_FILE=$DATA_LOG_PATH/imp.log
#
while true
do
  echo "Running ..."
  $DATA_PRO_PATH/import1.bash $DB_NAME 2>&1 | tee -a $DATA_LOG_FILE
  echo "Sleeping 30 seconds ..."
  /bin/sleep 30
done
