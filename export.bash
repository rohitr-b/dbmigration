#!/usr/bin/bash
. $HOME/.profile
#
DATA_LOG_PATH=/db2/db2m/AdmTbl/migrate/logs
PAR_CNS=5
COUNTER=0
#
rm $DATA_LOG_PATH/*.log
while read x y
do
  CNTEXPS=`ps -ef|grep -c export1.bash`
  while [ $CNTEXPS -gt $PAR_CNS ]; do
    /usr/bin/sleep 1
    CNTEXPS=`ps -ef|grep -c export1.bash`
  done
  let COUNTER=COUNTER+1
  echo "#: $COUNTER - Exporting $x - $y"
  LOG_FILE=$DATA_LOG_PATH/${y}.log
  nohup ./export1.bash m0rtsts1 $x $y > $LOG_FILE 2>&1 &
done < input.txt
