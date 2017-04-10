#!/bin/bash
#
. $HOME/.bash_profile
#
if [[ ! ("$#" == 1) ]]; then
  echo "One argument required."
  exit 1
fi
#
DATA_EXP_PATH=/db2/db2m/AdmTbl/migrate/tabledata
DATA_IMP_PATH=/db2/backup/aixmigration/sample/tabledata
DATA_PRO_PATH=/db2/backup/aixmigration/sample
DATABASE_NAME=$1
DATA_PRO_GA=$DATA_PRO_PATH/genalways.txt

db2 connect to $DATABASE_NAME

for DATAFILE in `find $DATA_IMP_PATH/*.ixf -mmin +3` ; do
  IFS='/ / / / / - .' read -a input_name <<< "$DATAFILE"
  DB_SCHEMA=${input_name[6]}
  DB_TABLE=${input_name[7]}
  DB_GAT=`grep -x -c $DB_TABLE $DATA_PRO_GA`
  #echo "Starting import of $DB_SCHEMA $DB_TABLE -- DB_GAT=$DB_GAT"
  DB_EXP_CNT_FILE=$DATA_IMP_PATH/$DB_TABLE.cnt
  DB_EXP_CNT=`grep "Number of rows exported" $DB_EXP_CNT_FILE | awk '{print $5}'`
  DB_IMP_CNT_FILE=$DATA_IMP_PATH/$DB_TABLE.impcnt
  DB2RET=1
  CNT_DB2=1
  while [ $DB2RET -ne 0 ]; do
    echo "-----------------------------------------------"
    echo "Loading table $DB_TABLE - Attempt: $CNT_DB2"
    if [ $DB_GAT -eq 1 ]; then
      db2 "load from $DATAFILE of ixf modified by identityoverride replace into "$DB_SCHEMA"."$DB_TABLE" nonrecoverable" | tee $DB_IMP_CNT_FILE
    else
      db2 "load from $DATAFILE of ixf replace into "$DB_SCHEMA"."$DB_TABLE" nonrecoverable" | tee $DB_IMP_CNT_FILE
    fi
    DB2RET=$?
    echo "Finished Import. Error Code: $DB2RET"
    let CNT_DB2=CNT_DB2+1
    if [ $DB2RET -eq 0 ]; then
      DB_IMP_CNT=`grep "Number of rows committed" $DB_IMP_CNT_FILE | awk '{print $6}'`
      if [ $DB_EXP_CNT -ne $DB_IMP_CNT ]; then
        echo "Import Rows of $DB_IMP_CNT does not match Export rows of $DB_EXP_CNT for table $DB_TABLE"
        echo "Retrying ..."
        DB2RET=1
      #else
      #  echo "Matched: Import Rows of $DB_IMP_CNT - Export rows of $DB_EXP_CNT for table $DB_TABLE"
      fi
    fi
  done
  /bin/gzip $DATAFILE
done
exit 0
