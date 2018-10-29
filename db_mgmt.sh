#!/bin/bash
#title           :db_mgmt.sh
#description     :This script will manage Oracle standalone Database 
#author		       :Hassan Besher A.K.A "N3tw0rk3r"
#date            :29102018
#version         :1.0    
#usage		       :bash db_mgmt.sh
#notes           :Make sure you are running the script with OS User in DBA Group .
#==================================================================================

#Define variables
EDITOR=vim
RED='\033[0;41;30m'
STD='\033[0;0;39m'

#User defined function
pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

#================================================

#DATABASE FUNCTIONS

#Start Database Lisenter
one(){
	lsnrctl start
        pause
}
 

#Stop Database Lisenter
two(){
	lsnrctl stop
        pause
}

#check Database status
three(){
VINSTANCE="v\$INSTANCE"
ALL_DB=`sqlplus -silent / as sysdba <<EOF
SELECT INSTANCE_NAME, STATUS, DATABASE_STATUS FROM $VINSTANCE;
EXIT;
EOF`
INSTANCE_NAME=`sqlplus -silent / as sysdba <<EOF
set heading OFF
select INSTANCE_NAME FROM $VINSTANCE;
EXIT;
EOF`
INSTANCE_STATUS=`sqlplus -silent / as sysdba <<EOF
set heading OFF
select STATUS FROM $VINSTANCE;
EXIT;
EOF`
DATABASE_STATUS=`sqlplus -silent / as sysdba <<EOF
set heading OFF
select DATABASE_STATUS FROM $VINSTANCE;
EXIT;
EOF`
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "       Database Listener Status"
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [[ $(lsnrctl status) = *Uptime* ]]; then
        echo "Listener is UP!"
else
        echo "Listener is Down!"
fi
        echo ""
        echo ""
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "       Database Instance Status"
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [[ "$ALL_DB" == *"ORACLE not available"* ]]; then
        echo  "Database Instance is Down!"

else
        echo  "Database Instance is UP!"
        echo  "Instance Name is: " $INSTANCE_NAME
        echo  "Instance Status is: " $INSTANCE_STATUS
        echo  "Database Status is: " $DATABASE_STATUS
fi
        pause
}

#Startup Database Instance Normally
four(){
	sqlplus -silent / as sysdba <<EOF
        startup
EOF
        pause
}

#Startup Database Instance with PFILE
five(){
read -p "Please Enter Full Path of PFILE: "  PFILE_PATH        
        sqlplus -silent / as sysdba <<EOF
        startup pfile= $PFILE_PATH
EOF
        pause
}

#Shutdown Database Instance
six(){
        sqlplus -silent / as sysdba <<EOF
        shutdown immediate
EOF

        pause
}

#Remove Database Locks
seven(){

while :
do

TABLE="v\$session"
TABLE2="GV\$SESSION"

SID_SERIAL=`sqlplus -silent / as sysdba <<EOF
set heading OFF
select SID||','||SERIAL# from $TABLE where SID in (select blocking_session from $TABLE) and ROWNUM = 1;
EXIT;
EOF`

INST_ID=`sqlplus -silent / as sysdba <<EOF
set heading OFF
select INST_ID from $TABLE2 where ROWNUM = 1;
EXIT;
EOF`



if [[ "$SID_SERIAL" == *"no rows selected"* ]]; then
        echo "You don't have any locks now!"
#       exit
#EOF
             break

elif [[ "$SID_SERIAL" != *"no rows selected"* ]]; then
         sqlplus -silent / as sysdba <<EOF
         alter system kill session '$SID_SERIAL,@$INST_ID' immediate;
EOF
fi

done

        pause
}

#View Tablespace Info
eight(){
TEMP_HEADER="v\$temp_space_header"

        sqlplus -silent / as sysdba <<EOF
        set heading OFF
        SELECT USER_TABLESPACES.TABLESPACE_NAME||' tablespace is '||USER_TABLESPACES.STATUS||' and '||
        USER_TABLESPACES.CONTENTS
        FROM USER_TABLESPACES join DBA_DATA_FILES
        on (USER_TABLESPACES.TABLESPACE_NAME=DBA_DATA_FILES.TABLESPACE_NAME);
EOF
        sqlplus -silent / as sysdba <<EOF
        SELECT /* + RULE */  df.tablespace_name "Tablespace",
       df.bytes / (1024 * 1024) "Size (MB)",
       SUM(fs.bytes) / (1024 * 1024) "Free (MB)",
       Nvl(Round(SUM(fs.bytes) * 100 / df.bytes),1) "% Free",
       Round((df.bytes - SUM(fs.bytes)) * 100 / df.bytes) "% Used"
       FROM dba_free_space fs,
       (SELECT tablespace_name,SUM(bytes) bytes
          FROM dba_data_files
         GROUP BY tablespace_name) df
       WHERE fs.tablespace_name (+)  = df.tablespace_name
       GROUP BY df.tablespace_name,df.bytes
       UNION ALL
       SELECT /* + RULE */ df.tablespace_name tspace,
       fs.bytes / (1024 * 1024),
       SUM(df.bytes_free) / (1024 * 1024),
       Nvl(Round((SUM(fs.bytes) - df.bytes_used) * 100 / fs.bytes), 1),
       Round((SUM(fs.bytes) - df.bytes_free) * 100 / fs.bytes)
       FROM dba_temp_files fs,
       (SELECT tablespace_name,bytes_free,bytes_used
          FROM $TEMP_HEADER
         GROUP BY tablespace_name,bytes_free,bytes_used) df
       WHERE fs.tablespace_name (+)  = df.tablespace_name
       GROUP BY df.tablespace_name,fs.bytes,df.bytes_free,df.bytes_used
       ORDER BY 4 DESC;
EOF
       sqlplus -silent / as sysdba <<EOF
        set heading OFF
        SELECT TABLESPACE_NAME||' tablespace datafiles:  '||FILE_NAME from DBA_DATA_FILES;
EOF
        pause
}

#View/Change current standard database audit settings
nine(){
VPARAMETER="v\$PARAMETER"
AUDIT_SETT=`sqlplus -silent / as sysdba <<EOF
set heading OFF
SELECT VALUE FROM $VPARAMETER WHERE NAME = 'audit_trail';
EXIT;
EOF`
        echo "Your current standard database audit is: " $AUDIT_SETT

        read -r -p "Do you want to change your current settings? [Y/n] " input
 
        case $input in
        [yY][eE][sS]|[yY])
        read -r -p "Please choose value [NONE | OS | DB | DB, EXTENDED | XML | XML, EXTENDED ] " value
         sqlplus -silent / as sysdba <<EOF
         set heading OFF
         alter system set audit_trail=$value scope=spfile;
EOF
         echo "To apply settings please restart Database Instance!"
pause   
     ;;
 
        [nN][oO]|[nN])
        pause
        ;;
 
       *)
       echo "Invalid input..."
       ;;
       esac


}

#Database Backup Recommendations
ten(){
#VCTRL="v\$CONTROLFILE"
#VPAR="v\$PARAMETER"
#CTRL_FILES_COUNT=`sqlplus -silent / as sysdba <<EOF
#set heading OFF
#SELECT count(name) FROM $VCTRL;
#EXIT;
#EOF`

#CTRL_FILES=`sqlplus -silent / as sysdba <<EOF
#set heading OFF
#SELECT VALUE FROM $VPAR WHERE NAME = 'control_files';
#EXIT;
#EOF`

#CTRL_FILES1=`sqlplus -silent / as sysdba <<EOF
#set heading OFF
#SELECT name from (SELECT name, ROWNUM AS RN FROM $VCTRL) WHERE RN = 1;
#EXIT;
#EOF`
#CTRL_FILES1=`sqlplus -silent / as sysdba <<EOF
#set heading OFF
#SELECT name from (SELECT name, ROWNUM AS RN FROM $VCTRL) WHERE RN = 1;
#EXIT;
#EOF`
#CTRL_FILES1=`sqlplus -silent / as sysdba <<EOF
#set heading OFF
#SELECT name from (SELECT name, ROWNUM AS RN FROM $VCTRL) WHERE RN = 1;
#EXIT;
#EOF`


#     echo "You have"$CTRL_FILES_COUNT" control file(s)"
#read -r -p "Would you like to view their names and locations? [Y/n]" CTRL_INPUT
#
#case $CTRL_INPUT in
#        [yY][eE][sS]|[yY])
#     echo $CTRL_FILES ;;
#
#        [nN][oO]|[nN])
#     echo "OK!"
#        ;;
#
#       *)
#       echo "Invalid input..."
#       ;;
#       esac

#read -r -p "Would you like to multiplex yout control files? [Y/n] " CTRL_INPUT2

#case $CTRL_INPUT2 in
#        [yY][eE][sS]|[yY])
#     read -r -p "Please Enter New control file name: " CTRL_NAME
#     read -r -p "Please Enter New control file location: " CTRL_LOC
#     cp $CTRL_FILES1 $CTRL_LOC/$CTRL_NAME

 #    sqlplus -silent / as sysdba <<EOF
  #       set heading OFF
  #       alter system set control_files='$CTRL_FILES1','$CTRL_FILES2','$CTRL_FILES3','$CTRL_LOC$CTRL_NAME';
#EOF
#   ;; 
    # echo= "DONE Created!"
#     [nN][oO]|[nN])
#     echo "OK!"
#        ;;

 #      *)
 #      echo "Invalid input..."
 #      ;;
 #      esac



        pause
}

#========================================================================================
# function to display menus
show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
	echo " Oracle 12c Database Management Script"
        echo "            By: N3tw0rk3r"	
        echo "          M A I N - M E N U"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Start Database Listener"
	echo "2. Stop Database Listener"
        echo "3. Check Listener/Database Status"
        echo "4. Startup Database Instance Normally"
        echo "5. Startup Database Instance using PFILE"
        echo "6. Shutdown Database Instance"
        echo "7. Clear Database Locks"
        echo "8. View Current Tablespace Info"
        echo "9. View/Change current standard database audit settings"
        echo "10. Database Backup Recommendations .....soon"
	echo "11. Exit"
}
# read input from the keyboard and take a action
# invoke the one() when the user select 1 from the menu option.
# invoke the two() when the user select 2 from the menu option.
read_options(){
	local choice
	read -p "Enter choice [ 1 - 10] " choice
	case $choice in
		1) one ;;
		2) two ;;
                3) three ;;
                4) four ;;
                5) five ;;
                6) six ;;
                7) seven ;;
                8) eight ;;
                9) nine ;;
                10) ten ;;
		11) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 1
	esac
}
 

#Trap CTRL+C, CTRL+Z and quit singles

trap '' SIGINT SIGQUIT SIGTSTP
 

#Main logic - infinite loop

while true
do
 
	show_menus
	read_options
done
