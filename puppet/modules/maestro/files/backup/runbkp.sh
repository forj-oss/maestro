#!/usr/bin/env bash
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
#---runbkp.sh V 1.0 --- based on mybkp_rsync.sh
#    - test: on dev instances wiki, jenkins, gerrit
#    - centralize in a standard refactorized script
#    - test: perfomance of configurations by a external file
# General Description:
#  This script will prepare the backups for instances 
#   I )  check for Database existance (now mysql service)
#   II)  run mysql backup based on innobackupex tool with an script that
#        runs the full backup. --
#   III) completes a backup of a packed FS with bup and rsync tools
#   note: for log lines format "Clasificacion: CURRENT_TIME <operation message>"
#         CURRENT_TIME = date +%d/%m-%k:%M
#---------------------------------------------------------------------------------------------

# =-==-=-==-=-==-=- Set variables -=-==-=-==-=-==-=

# Path to the bkp_<APP_NAME>.conf file
CONF_FILE=$1

## mode flag ----
#--- perform the different modes of how this script runs
if [ -z $2 ]; then
    MODE="P"
else
    MODE=$2
fi

## system variables
BKP_WEEK=$(date +'%Y-%W')                        #--- sets standard date for destiny folders, used for backups organization.
HOST_NAME="$HOSTNAME"                            #--- Host name
CURRENT_TIME=$(date '+%Y-%m-%d_%H-%M-%S')        #--- set for log events

##---=  backup setup variables =---##
SSH_CONFIG_HOST=""                               #--- to be set as part of configurations provided and confirmatio 
APP_NAME=""                                      #--- application name (used as part of bkp folder base ): jenkins, gerrit, wiki, Nexus
APP_LOCATION=""                                  #--- Path to source folder where is located all files to be backup
BKP_REMOTE_LOCATION=""                           #--- remote backup history: "backups"/"$HOST_NAME"/"$APP_NAME"
BKP_FILES_NAME=""                                #--- base name for the bup save function: $APP_NAME"_files"
BKP_LOCAL_LOCATION=""                            #--- local backup folder "/mnt/$APP_NAME/"
BUP_REPO=""                                      #--- local backup folder "/mnt/$APP_NAME/bup_repo/"
LOG_FILE=""                                      #--- "$APP_LOCATION/logs " will be the container for this log file, name: $APP_NAME".log""
LOGS_DIR=""                                      #--- folder for log file & DB backups: "$APP_LOCATION/logs"
BUP_PATH=""                                      #--- all the file system locations to include into the bup directory ie. ("$APP_LOCATION $DB_BKP_DIR")

####################################################################################################################################################################
############################################          Database section           ###################################################################################
####################################################################################################################################################################
TAROPTS="-cvPf"                                  # ---- "czvPf" Tar options to (c)create, (z)compress, (v)verbose, (P)preserve absolute names, (f) the specific file
TIMESTAMP=$( date +%Y%m%d )
CLEAR_DB_DAY="7"                                 # ---- day of the week when to perform a cleanup of "DB history backups" days: 1-7 (Monday - Sunday)

DB_USER=""                                       # ---- (e.g.: DB_USER=wikiuser)
DB_PWD=""                                        # ---- "$DB_PWD"   # (e.g.: user password)
DB_NAME=""                                       # ---- "reviewdb"
DB_BKP_DIR=""                                    # ---- "where backup folder will be placed" "/tmp/sql_db"
DB_BKP_NAME=""                                   # ---- "${APP_NAME}.sql"
DB_BKP_TOOL=""                                   # ---- choice for DB› backup tool "Default" mysqldump
SQL_PARAMS=""                                    # ---- Default options to use mysqldump ie. "-u $DB_USER -p$DB_PWD -E --verbose --databases $DATABASES"


ERRORS=0                                         # ---- Variable to catch all the error during the execution.
WARNINGS=0                                       # ---- Variable to catch all the warning during the execution.
####
## ---  here is were placed an automatic install repo for percona.
####

function bkhclean { #---- clean the history of innobackups from the folder and left just two days bkp history locally
  case "${DB_BKP_TOOL}" in
    '/usr/bin/mysqldump')
          echo "${DB_BKP_DIR}/"
          find "${DB_BKP_DIR}/" -name "*.sql" -exec rm -rf {} \;
    ;;
    '/usr/bin/innobackupex-1.5.1')
          find "${DB_BKP_DIR}/" -name "*.tar.gz" -exec rm -rf {} \;
    ;;
  esac
}

function chkbkdir { #---- checks the DB backup destiny folder exists
  if [ -d "${DB_BKP_DIR}" ] ;then
          rm -r "${DB_BKP_DIR}"
  fi
  mkdir -p "${DB_BKP_DIR}"

  # delete the local history on the day that you decide with the 'CLEAR_DB_DAY' variable.
  if [ "${CLEAR_DB_DAY}" == "$(date +%u)" ] ; then  # sets the rotation for the DB backup tar.gz files
          bkhclean
  fi
}

function db_env_vars {
   DB_BKP_DIR="/tmp/sql_db"
   DB_BKP_NAME="${APP_NAME}.sql"
}

function setmysqldump { ## mysqldump function for mysql fullbackup
   db_env_vars
   chkbkdir                   # verify DB folder
   service mysql status | grep 'mysql start/running'
   if [ $? -ne 0 ] ; then
        echo "- ERROR   : $CURRENT_TIME : Mysql service does not appear to be running." >> $LOG_FILE
        ERRORS=$((ERRORS+1))
        #exit 1
   else
        DB_BKP_FILE="${DB_BKP_DIR}/${DB_BKP_NAME}"
        echo "- Info   : $CURRENT_TIME : mysqldump process begin" >> $LOG_FILE
        DATABASES=$(echo $DB_NAME |sed 's/,/ /1g' )
        SQL_PARAMS="-u ${DB_USER} -p${DB_PWD} -E --add-drop-database --verbose --databases ${DATABASES} --log-error=$LOG_FILE --"
        $DB_BKP_TOOL $SQL_PARAMS > $DB_BKP_FILE      # will run mysqldump with specific options
        if [[ $? -eq 0 ]] ; then
                 echo "- Success: $CURRENT_TIME : mysqldump completed successfully" >> $LOG_FILE
                 echo "- Success: $CURRENT_TIME : mysqldump for databases (${DATABASES}) completed successfully" >> $LOG_FILE
                 echo "- Info   : $CURRENT_TIME : DB backup file size :$(ls -ldSh $DB_BKP_FILE | sed -n '1p' | awk '{print $5}')" >> $LOG_FILE
                 echo "- Info   : $CURRENT_TIME : DB backup file path :$(ls -ldSh $DB_BKP_FILE | sed -n '1p' | awk '{print $9}')" >> $LOG_FILE
        else
                 echo "- ERROR  : $CURRENT_TIME : mysqldump process failed" >> $LOG_FILE
                 ERRORS=$((ERRORS+1))
                 #exit 1
        fi
   fi
}

function db_backup {  #---- check info available for DB server access and backup tool
    echo "- Process: $CURRENT_TIME : Begin Validation to set DB backup tool" >> $LOG_FILE

    DB_NAME=$(cat $CONF_FILE | cut -d "#" -f1 | awk ' BEGIN { FS=":" } /^db_name/ {print $2}' | cut -d " " -f1 )
    if [ -z $DB_NAME ]; then
            echo "- ERROR  : $CURRENT_TIME : Database name not provided" >> $LOG_FILE
            ERRORS=$((ERRORS+1))
            #exit 1
    fi

    DB_USER=$(cat $CONF_FILE | cut -d "#" -f1 | awk ' BEGIN { FS=":" } /^db_user/ {print $2}' | cut -d " " -f1 )
    if [ -z $DB_USER ]; then
            echo "- ERROR  : $CURRENT_TIME : Database user not provided" >> $LOG_FILE
            ERRORS=$((ERRORS+1))
            #exit 1
    fi

    DB_PWD=$(cat $CONF_FILE | cut -d "#" -f1 | awk ' BEGIN { FS=":" } /^db_pwd/ {print $2}' | cut -d " " -f1 )
    if [ -z $DB_PWD ]; then
            echo "- ERROR  : $CURRENT_TIME : Database password not provided" >> $LOG_FILE
            ERRORS=$((ERRORS+1))
            #exit 1
    fi

# ---Database backup tool to use
    DB_BKP_TOOL="$(cat $CONF_FILE | cut -d '#' -f1 | awk ' BEGIN { FS=":" } /^db_bkp_tool/ {print $2}' | cut -d " " -f1 )" #verify the answer for db usage
    if [ -z $DB_BKP_TOOL ]; then
            echo "- ERROR  : $CURRENT_TIME : No database backup tool set, please set DB_BKP_TOOL property" >> $LOG_FILE
            ERRORS=$((ERRORS+1))
            #exit 1
    fi
    echo "- Info   : $CURRENT_TIME : DB backup tool choosen $DB_BKP_TOOL" >> $LOG_FILE
    DB_BKP_TOOL_NAME=$DB_BKP_TOOL
    case "$DB_BKP_TOOL" in
    'mysqldump')
          DB_BKP_TOOL="/usr/bin/mysqldump"
          setmysqldump
    ;;
    'innobackupex')
          DB_BKP_TOOL="/usr/bin/innobackupex-1.5.1"
          #setXtrabackup     # innobackupex functionality unused and removed.
    ;;
    *)
          echo "- ERROR  : $CURRENT_TIME : the database backup tool $DB_BKP_TOOL does not exists." >>$LOG_FILE
          ERRORS=$((ERRORS+1))
          #exit 1
    ;;
    esac
}

function bup_init { # --- perform the bup init and validates
   echo "- Running: $CURRENT_TIME : Initializing bup repository " >> $LOG_FILE
   bup -d $BUP_REPO init
   if [[ $? -ne 0 ]]; then
           echo "- ERROR  : $CURRENT_TIME : bup repo initializing not successful " >> $LOG_FILE
           ERRORS=$((ERRORS+1))
           #exit 1
   else
           echo "- Success: $CURRENT_TIME : bup repo created at $BUP_REPO" >> $LOG_FILE
   fi
}

function chk_log {  # Validates the log file; if exists Checks OK, else creates the file
    LOG_FILE="$LOGS_DIR/bup_$(date '+%Y-%m-%d_%H-%M-%S')_$$.log"
    if [ ! -d "$LOGS_DIR" ]; then
        mkdir -p $LOGS_DIR
    fi
    echo "- Success: $CURRENT_TIME :  log created: OK" >> $LOG_FILE
    if [ "$(date +%u)" = "${CLEAR_DB_DAY}" ]; then
         echo "- Success: $CURRENT_TIME : log rotation, Start Backup for week" >> $LOG_FILE
    fi  
}

function create_week_dir { # --- verifies the initialization of remote folders
     if [[ -d "$( ssh ${SSH_CONFIG_HOST} ls -l ${BKP_REMOTE_LOCATION}/${BKP_WEEK} )" ]] ; then
         echo "- Success: $CURRENT_TIME : remote Backup folder availability OK" >> $LOG_FILE
     else
         echo "- Running: $CURRENT_TIME : Creating remote Folder $BKP_WEEK " >> $LOG_FILE
         ssh $SSH_CONFIG_HOST " mkdir -p ${BKP_REMOTE_LOCATION}/${BKP_WEEK} " >> $LOG_FILE
         ssh $SSH_CONFIG_HOST " chmod 755 -R ${BKP_REMOTE_LOCATION}/${BKP_WEEK} " >> $LOG_FILE
         if [ $? -eq 0 ] ; then
           echo "- Success: $CURRENT_TIME : folder $BKP_WEEK created OK" >> $LOG_FILE
         else
           echo "- ERROR  : $CURRENT_TIME : error trying to create ${BKP_REMOTE_LOCATION}/${BKP_WEEK} folder remotely using ssh " >> $LOG_FILE
           #exit 1
         fi
     fi
}

function create_backup_info(){ # --- sets information to be consulted about the backup
      BKP_INFO="$LOGS_DIR/info_$(date '+%Y-%m-%d_%H-%M-%S')_$$.yaml"
      touch  $BKP_INFO
      echo "#-- Backup information file --" >> $BKP_INFO
      echo "last_update: \"$(date '+%Y-%m-%d_%H-%M-%S')\"" >> $BKP_INFO
      echo "application: \"${APP_NAME}\"" >> $BKP_INFO
      echo "bup_name: \"${BKP_FILES_NAME}\"" >> $BKP_INFO
      echo "source_folder: \"${APP_LOCATION}\"" >> $BKP_INFO
      echo "db_backup_tool: \"${DB_BKP_TOOL_NAME}\"" >> $BKP_INFO
      echo "databases: \"${DATABASES}\"" >> $BKP_INFO      
      tbkfls=$( find $BUP_PATH -print | wc -l )           # obtain the number of files and folders saved
      echo "number_of_files: $tbkfls" >> $BKP_INFO
      echo "errors: $ERRORS" >> $BKP_INFO
      echo "warnings: $WARNINGS" >> $BKP_INFO
      if [ -n $APP_LOCATION ]; then
            cp "${BKP_INFO}" "${APP_LOCATION}/info.yaml"
      elif [ -n $DATABASES ]; then
            cp "${BKP_INFO}" "${DB_BKP_DIR}/info.yaml"
      fi
}

function rsyncbup { # --- generates the sincronization from local and remote folder
      create_week_dir
      rsync -avz -e ssh $BKP_LOCAL_LOCATION $SSH_CONFIG_HOST:$BKP_REMOTE_LOCATION/$BKP_WEEK
      if [[ $? -eq 0 ]] ; then
            echo "- Info   : $CURRENT_TIME : Backup process completed" >> $LOG_FILE
            rsync -avz -e ssh $BKP_LOCAL_LOCATION $SSH_CONFIG_HOST:$BKP_REMOTE_LOCATION/$BKP_WEEK  # --- will send the last line of the log :)
      else
            echo "- ERROR  : $CURRENT_TIME : The Backup could not be send to maestro" >> $LOG_FILE
            ERRORS=$((ERRORS+1))
            create_backup_info
            exit 1
      fi
}

function bupsave {    #--- performs the bup operations to create the backup repository
      echo "- Info   : $CURRENT_TIME : Starting bup save process" >> $LOG_FILE
      if [ -n $APP_LOCATION ]; then
              BUP_PATH=$APP_LOCATION
      fi
      if [ -n $DB_BKP_DIR ]; then
              BUP_PATH="${BUP_PATH} ${DB_BKP_DIR}"
      fi
      create_backup_info
      tar $TAROPTS - $BUP_PATH | bup -d $BUP_REPO split --name=$BKP_FILES_NAME >> $LOG_FILE
      if [[ $? -eq 0 ]] ; then
             echo "- Success: $CURRENT_TIME : bup save finish OK" >> $LOG_FILE
             echo "- Success: $CURRENT_TIME : bup save finish OK"
      else
             echo "- ERROR  : $CURRENT_TIME : bup save process failed, please check your file system ($BUP_PATH) and the bup repo ($BUP_REPO)" >> $LOG_FILE
             ERRORS=$((ERRORS+1))
             create_backup_info
             #exit 1
      fi
}

function rewval {
      BKP_LOCAL_LOCATION="/mnt/${APP_NAME}/"
      BUP_REPO="${BKP_LOCAL_LOCATION}bup_repo/"
      LOGS_DIR="${BKP_LOCAL_LOCATION}logs"
      BKP_REMOTE_LOCATION="/mnt/backups/${HOST_NAME}/${APP_NAME}"      
      chk_log
}

function CreateRBack {  #Central function of backup functions
      echo "- Info   : $CURRENT_TIME : Starting Backup process" >> $LOG_FILE
      DB_BACKUP_ENABLED="$(cat $CONF_FILE | cut -d '#' -f1 | awk ' BEGIN { FS=":" } /^db_bkp_enabled/ {print $2}' | cut -d " " -f1 )" #verify the answer for db usage
      if [ -z "${DB_BACKUP_ENABLED}" ] && [ -z "${APP_LOCATION}" ]; then
               echo "- ERROR  : $CURRENT_TIME : There is no file system or databases to backup. check your config file." >>$LOG_FILE
               ERRORS=$((ERRORS+1))
               #exit 1
      fi
      bup_init
      if [ "${DB_BACKUP_ENABLED}" = "true" ]; then
               db_backup              # --- invoque the setup data check for DB backup
               echo "- Running: $CURRENT_TIME : Start backup Filesystem operations" >>$LOG_FILE
               echo "- Running: $CURRENT_TIME : Start backup Filesystem operations"
      fi
      bupsave      
      rsyncbup
}

function chkconff {    # --= check availability of config file

  APP_NAME=$(cat $CONF_FILE | cut -d "#" -f1 | awk ' BEGIN { FS=":" } /^app_name/ {print $2}' | cut -d " " -f1 )
  if [ -z "${APP_NAME}"  ]; then
          echo "- ERROR  : $CURRENT_TIME : app config header not specified"
          exit 1
  fi
  
  #CREATE LOGS_DIR and LOG_FILE
  rewval
  
  SSH_CONFIG_HOST=$(cat $CONF_FILE | cut -d "#" -f1  | awk ' BEGIN { FS=":" } /^ssh_config_host/ {print $2}' | cut -d " " -f1 )
  if [ -z "${SSH_CONFIG_HOST}" ]; then
          echo "- ERROR  : $CURRENT_TIME : ssh conf name not specified" >> $LOG_FILE
          #exit 1
  fi
  
  APP_LOCATION=$(cat $CONF_FILE | cut -d "#" -f1  | awk ' BEGIN { FS=":" } /^app_location/ {print $2}' | cut -d " " -f1 )
  if [ -z "${APP_LOCATION}" ]; then
          echo "- WARNING: $CURRENT_TIME : Application folder not specified" >> $LOG_FILE
          WARNINGS=$((WARNINGS+1))
  elif [ ! -d "${APP_LOCATION}" ]; then
          echo "- ERROR  : $CURRENT_TIME : The Application folder is not valid, app_location=${APP_LOCATION}" >> $LOG_FILE
          ERRORS=$((ERRORS+1))
          #exit 1
  fi  

  BKP_FILES_NAME=$(cat $CONF_FILE | cut -d "#" -f1  | awk ' BEGIN { FS=":" } /^bkp_name/ {print $2}'| cut -d " " -f1 )
  if [ -z "${BKP_FILES_NAME}" ]; then
          echo "- ERROR  : $CURRENT_TIME : backup name not specified" >> $LOG_FILE
          ERRORS=$((ERRORS+1))
          #exit 1
  fi
  
  CreateRBack
}

case "$MODE" in
[M,m])
       #not implemented
;;
[A,a])
       #not implemented
;;
p|P)
       if [ -f "$CONF_FILE" ]; then
              chkconff
       else
              echo "- ERROR  : $CURRENT_TIME the config file (${CONF_FILE}) does not exist"
              exit 1
       fi
       if [[ $ERRORS -eq 0 ]] ; then
              exit 0
       else
              echo "- ERROR  : $CURRENT_TIME : Total errors found $ERRORS" >> $LOG_FILE
              exit 1
       fi
;;
esac