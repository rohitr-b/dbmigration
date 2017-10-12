#!/usr/bin/bash
. $HOME/.profile

DATA_EXP_PATH=/db2/db2m/AdmTbl/migrate/tabledata
DATA_IMP_PATH=/db2/backup/aixmigration/sample/tabledata
DATA_LOG_PATH=/db2/db2m/AdmTbl/migrate/logs
DATABASE_NAME=$1
SCHEMA_NAME=$2
TABLE_NAME=$3

db2 connect to $DATABASE_NAME

DATA_EXP_FILE="$DATA_EXP_PATH/$SCHEMA_NAME-$TABLE_NAME.ixf"
DATA_ROW_CNT=$DATA_LOG_PATH/$TABLE_NAME.cnt
DB2RET=1
CNT_DB2=1
while [ $DB2RET -ne 0 ]; do
  echo "Exporting file $DATA_EXP_FILE - Attempt $CNT_DB2"
  db2 "export to $DATA_EXP_FILE of ixf select * from $SCHEMA_NAME.$TABLE_NAME" | tee $DATA_ROW_CNT
  DB2RET=$?
  echo "Finished Export. Error Code: $DB2RET"
  let CNT_DB2=CNT_DB2+1
done
#
echo "
------------------------
"
#
# Checksum
#
CHK_FILE="$DATA_EXP_PATH/$SCHEMA_NAME-$TABLE_NAME.md5"
csum -h MD5 -o $CHK_FILE $DATA_EXP_FILE
#
# Copy file to Linux/core.
#
SCPRET=1
CNT_EXP=0
while [ $SCPRET -ne 0 ]; do
  let CNT_EXP=CNT_EXP+1
  echo "Copying file $DATA_EXP_FILE - Attempt $CNT_EXP"
  scp -o ConnectTimeout=5 $DATA_EXP_FILE $DATA_ROW_CNT db2insta@IP.00.168.000:$DATA_IMP_PATH
  SCPRET=$?
  if [ $SCPRET -eq 0 ]; then
    echo "Finished Copy. Error Code: $SCPRET"
    #
    # Get copied md5sum and check.
    #
    CHK_FILE_TARG="$DATA_EXP_PATH/$SCHEMA_NAME-$TABLE_NAME.target.md5"
    SSHRET=1
    CNT_SSH=1
    while [ $SSHRET -ne 0 ]; do
      echo "Getting Target chksum. Attempt: $CNT_SSH"
      ssh -n db2insta@IP.ADDR.168.00 "/usr/bin/md5sum $DATA_IMP_PATH/$SCHEMA_NAME-$TABLE_NAME.ixf" > $CHK_FILE_TARG
      SSHRET=$?
      let CNT_SSH=CNT_SSH+1
    done
    #
    CHKSRC=`cat $CHK_FILE | awk '{print $1}'`
    CHKTARG=`cat $CHK_FILE_TARG | awk '{print $1}'`
    if [ $CHKSRC = $CHKTARG ]; then
      rm $DATA_EXP_FILE
    else
      echo "Checksum mismatch for $SCHEMA_NAME-$TABLE_NAME.  File: DATA_EXP_FILE"
      SCPRET=1
    fi
  fi
done
#
exit 0
