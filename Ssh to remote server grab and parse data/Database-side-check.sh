#!/bin/bash




################### ###################### ######################

# General
dlc=/opt/dlc/bin
db_dir=/db1/
src_dir=/home/progress/scripts

cd $db_dir
dblist=`ls -1|grep -v repl`
#dblist='accrec common prepcdr'


error_exit()
{
   echo -e "\nInvalid arguments: $0 -all | -db [v|vv|s|u \"option name\"] | -repl [v|vv|s] \n"
   echo -e "-db    - Database info\n-repl  - Replication info\n-all   - Database + Replication info\n"
   echo -e "v  - short info\nvv - full info\ns  - status (UP or DOWN)\nu  - user option\n"
   exit 1
}

function promon_db_status
{
        echo "7"
        echo -ne "\n"
        echo "q"
        echo "q"
}

function dsrutil_repl_status
{
	echo "r"
        echo "1"
        echo -ne "\n"
        echo "q"
        echo "q"
}

db_info()
{
	for dbname in $dblist; do
	        echo -e "\n"================================== $dbname ====="\n"
		promon_db_status | $dlc/promon $db_dir/$dbname/$dbname 2>/dev/null | grep "$1"
	done;
	echo -e "\n"
}

db_status()
{
        for dbname in $dblist; do
		DB_STS=`promon_db_status | $dlc/promon $db_dir/$dbname/$dbname 2>/dev/null | grep "Database state: Open (1)" | wc -l`
		if [ $DB_STS = 0 ]; then
			echo 2
			exit 2
		fi
        done;
}

replication_info()
{
        for dbname in $dblist; do
                echo -e "\n"================================== $dbname ====="\n"
		#--- replication status (DSRUTIL)
		dsrutil_repl_status | $dlc/dsrutil $db_dir/$dbname/$dbname -C monitor 2>/dev/null | grep "$1"; echo
		#--- AI files info (RFUTIL)
        	$dlc/rfutil $db_dir/$dbname/$dbname -C aimage list | grep "$2"
        done;
        echo -e "\n"
}

replication_status()
{
        for dbname in $dblist; do
		#--- check empty ai files 
                AI_EMPTY=`$dlc/rfutil $db_dir/$dbname/$dbname -C aimage list | grep "Status:  Empty" | wc -l`
                if [ $AI_EMPTY = 0 ]; then
                        echo 1
                        exit 1
                fi

		#--- max ai file
		MAX_AI=`$dlc/rfutil $db_dir/$dbname/$dbname -C aimage list | grep Seqno | cut -d " " -f 4 | sort -r | head -1`
		#--- sequence from "Current RDBMS Block"
		CRB=`dsrutil_repl_status | $dlc/dsrutil $db_dir/$dbname/$dbname -C monitor 2>/dev/null | grep "Current RDBMS Block (Seq / Block)" | cut -d " " -f 20`
		#--- sequence from "Last Sent Block"
		LSB=`dsrutil_repl_status | $dlc/dsrutil $db_dir/$dbname/$dbname -C monitor 2>/dev/null | grep "Last Sent Block (Seq / Block)" | cut -d " " -f 24`
		count=`expr $CRB - $LSB`
		if [ $count -ne 0 ]; then
        		if  [ $count -lt 3 ]; then
#                		echo 1" "$dbname" "$CRB" "$LSB
				echo 1
				exit 1
        		else
                		echo 2
				exit 2
        		fi
		fi
        done;
}

all_info()
{
        for dbname in $dblist; do
		echo -e "\n"================================== $dbname ====="\n"
		echo -e "DB status: ----------------------------\n"
		promon_db_status | $dlc/promon $db_dir/$dbname/$dbname 2>/dev/null | grep "$1"; echo
		echo -e "Replication status:--------------------\n"
		dsrutil_repl_status | $dlc/dsrutil $db_dir/$dbname/$dbname -C monitor 2>/dev/null | grep "$2"; echo
#                $dlc/rfutil $db_dir/$dbname/$dbname -C aimage list | grep "$3"
        done;
        echo -e "\n"
}

p_class=${1:--all}
unset STATUS

################### main ################################

case $p_class in
-all)
	filter_db='Database state\|Most recent full backup'
	filter_dsr='State\|Critical\|(Seq / Block)'
	filter_rf='Status\|Seqno'
	all_info "$filter_db" "$filter_dsr" "$filter_rf"
        ;;
-db)
	if [ $# -gt 1 ]; then
                case $2 in
			vv)
				filter_db=':'
				;;
                        v)
                                filter_db='Database state\|Most recent full backup'
                                ;;
			u)
				filter_db=$3
				;;
			s)
				STATUS=YES
				;;
			*)
				error_exit
				;;
		esac
        else
                filter_db='Database state\|Most recent full backup'
        fi
	
	if [ x$STATUS = "x" ]; then
		db_info "$filter_db"
	else
		db_status
		echo 0
	fi
        ;;
-repl)
        if [ $# -gt 1 ]; then
                case $2 in
                        vv)
                                filter_dsr=' '
				filter_rf=' '
                                ;;
                        v)
                                filter_dsr='State\|Critical\|(Seq / Block)'
                                filter_rf='Status\|Seqno'
                                ;;
			s)
				STATUS=YES
				;;
                        *)
                                error_exit
                                ;;
                esac
        else
		filter_dsr='State\|Critical\|(Seq / Block)'
		filter_rf='Status\|Seqno'
        fi


        if [ x$STATUS = "x" ]; then
		replication_info "$filter_dsr" "$filter_rf"
        else
                replication_status
		echo 0
        fi
        ;;
*)
        error_exit
        ;;
esac

################### END SCRIPT ##########################
