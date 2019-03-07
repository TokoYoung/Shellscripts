#!/bin/sh
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin; export PATH

#############################################################################################################################################################

/bin/echo -e -n "\\n\\n`/bin/date "+%Y-%m-%d %H:%M:%S"` $0 STARTED.\\n\\n"

#############################################################################################################################################################

sdate=`/bin/date +%y%m%d`
ldate=`/bin/date +%H%M%S`
cpid=$$
tfile="/usr/local/smsmonsys/tmp/$sdate$ldate$cpid"

#############################################################################################################################################################

# Delete old temp file
/bin/rm -f $tfile

# Get data from server and put it into file

/usr/local/smsmonsys/checkrbs/rbsreplication/rbs-repl-status.exp > $tfile

# Remove end of line characters
/usr/bin/dos2unix $tfile

# Print file

/bin/cat $tfile

#############################################################################################################################################################

# accrec
db_name="accrec"
dbrepl_status=`/bin/grep -e "^$db_name " $tfile | /bin/awk -F ' ' {'print $3'}`
dbrepl_state=`/bin/grep -e "Critical" $tfile | /bin/awk-F ' ' {'print $2'}`

# If dbrepl_status is empty then 'unknown'
if [ -z "$db_status" ]; then
 dbrepl_status="UNKNOWN"
fi


# If dbrepl_state is empty then 'unknown'
if [ -z "$db_state" ]; then
 dbrepl_state="UNKNOWN"
fi

# Convert data base name  to uppercase

db_name=`/bin/echo $db_name | /usr/bin/tr a-z A-Z`

/bin/echo -e -n "\n"

/bin/echo "DB NAME: '$db_name'"
/bin/echo "Replication Status: '$dbrepl_status'"
/bin echo "Replication State": '$dbrepl_state'

/bin/echo -e -n "\n"

if [[ $dbrepl_state == "Processing" ]]; then
  /usr/local/healthmonsys/hmsud.sh RBS-REPLICATION-STATE-"$db_name" "$db_name" "OK $dbrepl_state" "GREEN"
  message="RBS-REPLICATION-STATE: '$db_name' status is: '$dbrepl_state'."
 #/usr/local/smsmonsys/alrmstatinf/alrmstatinf.sh OK RBS-REPLICATION-STATUS-"$db_name" FAKELIST "$message"
	
	fi
		#else
 	#/usr/local/healthmonsys/hmsud.sh RBS-REPLICATION-STATUS-"$db_name" "$db_name" "ALARM $db_status" "RED"
  #message="RBS Database: '$db_name' status is: '$dbrepl_status'."
 #/usr/local/smsmonsys/alrmstatinf/alrmstatinf.sh ALARM RBS-DB-STATUS-"$db_name" FAKELIST "$message"

#############################################################################################################################################################

# Delete temp file
#/bin/rm -f $tfile

#############################################################################################################################################################

/bin/echo -e -n "\\n\\n`/bin/date "+%Y-%m-%d %H:%M:%S"` $0 STOPPED.\\n\\n"

#############################################################################################################################################################


exit 0
