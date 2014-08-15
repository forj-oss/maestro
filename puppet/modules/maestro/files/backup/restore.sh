#!/bin/bash
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#### comment to be amended
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# restore.sh script, placed in box to perform backup restore of App files.
# used to run in dependency of restoreraid
#

SC_MODE="$1"                                                                            #--- Will define if the repos will be pulled from a remotely source or locally  ie -p or -l
APP_NAME="$2"                                                                           #--- Application name; sets the name for the restore folder
BKP_CONTENT="$3"                                                                        #--- Indicates the path of the repo source to be restored (could be local or remote)
WEEK_NUM=$( echo "$BKP_CONTENT" | awk 'BEGIN { FS="/" } { print $NF } ' )               #--- Returns 2014-30
BKP_APP_DIR=""                                                                          #--- Contains the bup app repository path.
BKP_LOG_DIR=""                                                                          #--- Contains the logs repository path.
IS_SERVICE=""                                                                           #--- Contains status value that shows app availability in the system
APP_LOCATION=""                                                                         #--- contains the App home folder
BKP_INFO=""                                                                             #--- directs the path to file where important data about the bkp is contained
BUP_CMD=""


#--- Harcoded Variables
REST_BASE_DIR="/mnt/restore"
REST_APP_DIR="$REST_BASE_DIR/$APP_NAME"                                                 #---where the pulled repo will be placed
LOG_FILE="${REST_BASE_DIR}/${APP_NAME}_restore.log"
REST_FILES_LOG="${REST_BASE_DIR}/${APP_NAME}_restfiles.log"
DB_DATA_DIR=$(grep datadir /etc/mysql/my.cnf | cut -d"=" -f2 | cut -d" " -f2)
SSH_CONFIG_HOST="forj-bck"                                                              #--- name of ssh configuration located on ~/.ssh/config file
REMOTE_LOG_DIR="/mnt/backups/restorelogs/"                                              #--- Remote folder for the restore logs
SQL_PARAMS=""                                                                           #--- Could be retrieved from a env var


#--- Error codes

RSYNC_ERROR=1               # Rsync Error
BKP_LOG_DIR_DOESNT_EXIST=2  # BKP_LOG_DIR doesnt exist
SERVICE_STOP_FAILED=3       # Service stop failed
BUP_NOT_INSTALLED=4         # Bup is not installed
WRONG_DIR_PERMISSIONS=5     # wrong permissions in a directory
BKP_CONTENT_DOESNT_EXIST=6  # BKP_CONTENT doesnt exist
SQL_FILE_DOESNT_EXIST=8     # Sql file doesnt exist
SERVICE_START_FAILED=9      # App didn't restart succesfully
MYSQL_NOT_INSTALLED=10      # Error : MySQL server no installed here
SSH_ERROR=11                # ssh error
BKP_INFO_DOESNT_EXIST=12    # BKP_INFO doesnt exist


function message(){
  local logtime="$(date '+%Y-%m-%d_%H-%M-%S')"
  local msg=$1
  if [ ! -f $LOG_FILE ]; then
          touch $LOG_FILE
          # Make the log readable and writable by the group and others:
          chmod go+rw $LOGFILE
  fi
  if [ -n "$msg" ] ; then
        echo "${logtime}: ${msg}"
        echo "${logtime}: ${msg}" >> $LOG_FILE
  fi
}


function set_bup_cmd(){
  hash bup 2>/dev/null || { echo >&2 message "Error: bup is not installed.  Aborting."; exit "$BUP_NOT_INSTALLED"; }
  BUP_CMD=$(which bup)

}


function pushlogs () { #--- send the log files to the central backup storage instance "maestro"
   flval=$1
   message "  - Operations : Sending log operation files to Remote central instance  $APP_LOCATION  "
   case $flval in
   "error")
         scp $LOG_FILE $SSH_CONFIG_HOST:$REMOTE_LOG_DIR
   ;;
   "success")
         scp $LOG_FILE $SSH_CONFIG_HOST:$REMOTE_LOG_DIR
         scp $REST_FILES_LOG $SSH_CONFIG_HOST:$REMOTE_LOG_DIR
   ;;
   esac
}


function ssh_cnf_chk { #--- set check of the ssh configurations
   ssh -t $SSH_CONFIG_HOST 'exit'
   if [ $? -eq 0 ]; then
          message "  - Success : SSH configurations are correct and working OK  "
   else
          message "  - Error   : SSH Configurations wrong or not set, verifi your setting in ~/.ssh/config "
          pushlogs "error"
          exit "$SSH_ERROR"  #--- ssh error
   fi
}


function pullfunc { #--- will receive parameters and do the pull of an specific folder to perform the restore
   if [ ! -d $REST_BASE_DIR ]; then
            message "  - Operations : Local Folder $REST_BASE_DIR created"
            mkdir -p  $REST_BASE_DIR
   fi
   if [ -d $REST_APP_DIR ]; then
            rm -rf  ${REST_APP_DIR}/*
            message "  - Operations : Removing old data from ${REST_APP_DIR}"
   fi
   rsync -avz $SSH_CONFIG_HOST:$BKP_CONTENT $REST_APP_DIR
   if [ $? -eq 0 ]; then
           message "  - Success : Folder synchronized with local $REST_APP_DIR created OK"
   else
           message "  - Error   : rsync operation fails, see log file errors "
           pushlogs "error"
           exit "$RSYNC_ERROR"  #--- rsync error
   fi
}


function getbkinffill { #--- get and fills the names of bkp and the path for the repo set
   BKP_APP_DIR="$(ls -d $REST_APP_DIR/$WEEK_NUM)/bup_repo"
   BKP_LOG_DIR="$(ls -d $REST_APP_DIR/$WEEK_NUM)/logs"
   if [ -d "$BKP_LOG_DIR" ]; then
            BKP_INFO=$( ls -t $BKP_LOG_DIR/info_*.yaml | head -1 )  #--- sets the path of the backup file info
            if [ -f "$BKP_INFO" ]; then
                    message "- Success: Data of backup $APP_NAME is available "
            else
                    message "- Error: Data of backup $APP_NAME isn't pulled complete, check the backup process "
                    exit "$BKP_INFO_DOESNT_EXIST"  #--- posibly something happened during the backup and the set of files are not complete
            fi
            BUP_NAME="$("$BUP_CMD" -d "${BKP_APP_DIR}" ls | cut -d"/" -f1)"                #--- gets the bup backup name from the repository
   else
            message "  - Error : $BKP_APP_DIR folder does not exists"
            pushlogs "error"
            exit "$BKP_LOG_DIR_DOESNT_EXIST"  #--- not listed folder for backup set
   fi
}


function get_home {  #---gets "path" and sets $APP_LOCATION variable
   message "  - Operations : Retrieving path for the application from the bup repository "
   APP_LOCATION=$( cat $BKP_INFO | awk ' BEGIN { FS=":" } /^source_folder/ {print $2}' | sed -e 's/^ "//'  -e 's/"$//') #--- will get the home from bup repo
}


function mvsqlfoldcp {  #--- Copy the current contents of mysql folder and leaves the one unaltered
   if [ -d "$DB_DATA_DIR" ]; then
          message "  - Operations : MYSQL app home folder will be copied to $DB_DATA_DIR.old "
          cp -Rfp $DB_DATA_DIR "${DB_DATA_DIR}.old"
          if [ $? -eq 0 ]; then
                 message "  - Success : we have copied MYSQL current home folder to $DB_DATA_DIR.old "
                 message "  - Operations : Original MYSQL app home preserved it path at: $DB_DATA_DIR "
          else
                 message "  - Error : MYSQL copy folder not created, by some error; maybe permissions or path are not correct, please verify "
                 exit "$WRONG_DIR_PERMISSIONS" #--- wrong permissions in a directory
          fi
   else
          message "  - Info : MYSQL app home folder not present, please read mysql manuals "
          mkdir -p  $DB_DATA_DIR              #--- default is "/var/lib/mysql"
          chown -R mysql:mysql $DB_DATA_DIR
          message "  - Info : MYSQL app home folder was created and permissions set, but service isn't installed yet "
   fi
}


function mvappfold { #--- set a copy of the app home dir and replace an empty app home folder
   get_home  #--- invoques the function that obtain from repo which is the home for
   message "  - Operations : Checking $APP_LOCATION folder availability"
   if [ -d "$APP_LOCATION" ]; then
           message "  - Success : $APP_LOCATION folder availability OK"
           OWNER=$( stat -c %U $APP_LOCATION )
           GROUP=$( stat -c %G $APP_LOCATION )
           if [ -d "${APP_LOCATION}.old" ]; then
                  rm -rf "${APP_LOCATION}.old"
           fi
           mv -f $APP_LOCATION  "${APP_LOCATION}.old"
           if [ $? -eq 0 ]; then
                  mkdir -p $APP_LOCATION
                  chown -R $OWNER:$GROUP $APP_LOCATION
                  message "  - Success : Folder set for  $APP_LOCATION created OK"
                  message "  - Success : Owner for Folder for app $APP_LOCATION set to ${OWNER}:${GROUP}  OK"
           else
                  message "  - Error : Folder $APP_LOCATION could not be overwritten; please check your User permissions"
                  pushlogs "error"
                  exit "$WRONG_DIR_PERMISSIONS"  #--- wrong permissions in a directory
           fi
   else
           message "  - Info : seems like folder $APP_LOCATION isn't available to move "
           message "  - Operations : Anyhow I'll create a new $APP_LOCATION folder  "
           mkdir -p $APP_LOCATION
           if [ $? -eq 0 ]; then
                  message "  - Success : Folder for $APP_LOCATION backup created OK  "
                  message "  - Operations : Setting permissions for new $APP_LOCATION folder "
                  OWNER=$( "$BUP_CMD" -d $BKP_APP_DIR join $BUP_NAME |tar -tPf - -v | sed -n '1p' | awk ' { print $2 } ' | cut -d"/" -f1  )
                  GROUP=$( "$BUP_CMD" -d $BKP_APP_DIR join $BUP_NAME |tar -tPf - -v | sed -n '1p' | awk ' { print $2 } ' | cut -d"/" -f2  )
                  message "  - Operations : Checking User existance in the system "
                  if [ -n "$( getent passwd $OWNER )" ]; then
                         chown -R $OWNER:$GROUP $APP_LOCATION
                         message "- Success: user exists, setting permissions to new $APP_LOCATION folder "
                  else
                         message "- Info: User not exists, to preserve permissions $OWNER will be created"
                         useradd -p $( mkpasswd -s $OWNER ) -s /bin/bash -d /home/$OWNER -m $OWNER
                         if [ $? -eq 0 ]; then
                                if [ -z "$( egrep -i "^${GROUP}" /etc/group )" ]; then
                                        groupadd $GROUP
                                fi
                                message "- Success: user exists, setting permissions to new $APP_LOCATION folder "
                                chown -R $OWNER:$GROUP $APP_LOCATION
                                message "  - Operations : Set permissions for new $APP_LOCATION folder "
                                message "  - Info : User created for backup is : $OWNER "
                                message "  - Info : Passwd created for backup user is : $OWNER "
                         else
                                message "  - Error : User $OWNER for $APP_LOCATION backup could not be created; please check your User permissions  "
                                pushlogs "error"
                                exit "$WRONG_DIR_PERMISSIONS"  #--- wrong permissions in a directory
                         fi
                  fi
           else
                  message "  - Error : Folder for app $APP_LOCATION not set; please check your User permissions  "
                  pushlogs "error"
                  exit "$WRONG_DIR_PERMISSIONS"  #--- wrong permissions in a directory
           fi
   fi
}


function mydumppush () {    #--- restores the mysql Databases "#-- Mysqldump --#
   message "  - Operations : checking the dump file for mysqldump restore "
   SQL_FILE=$( ls -dS /tmp/sql_db/${APP_NAME}.sql | sed -n '1p')
   if [ -f "$SQL_FILE" ]; then
          message "  - Success : dump file for mysqldump restore $SQL_FILE is available "
          message "  - Operations : checking the dump file for mysqldump restore $SQL_FILE "
          SQL_PARAMS="-u $(cat /etc/forj/conf.d/bkp_${APP_NAME}.conf |sed -n '/db_user/p' | cut -d':' -f2) -p$(cat /etc/forj/conf.d/bkp_${APP_NAME}.conf |sed -n '/db_pwd/p' | cut -d':' -f2 ) "
          mysql $SQL_PARAMS < $SQL_FILE
          if [ $? -eq 0 ]; then
                  message "  - Success : mysqldump restore concludes Succesfully "
          else
                  message "  - Error : mysqldump restore process failed please verify your file or permissions "
                  pushlogs "error"
                  exit 8 #--- mysqldump restore failed
          fi
   else
          message "  - Error : dump file for mysqldump file not available "
          message "- Error : mysqldump copy-back operations Failed "
          pushlogs "error"
          exit "$SQL_FILE_DOESNT_EXIST" #--- MySql file doesnt exist
   fi
}


function bupjoin { #--- Depends on getbkname function to be accomplished first
      message "  - Operations : start the Restoring of files and folders in $APP_LOCATION  "
      if [ -n "$BUP_NAME" ]; then
                  echo "  - Operations : List of restored files and folders in $APP_LOCATION :  " >> $REST_FILES_LOG
                  "$BUP_CMD" -d $BKP_APP_DIR join $BUP_NAME | tar  xvpPf - -C / -v >$REST_FILES_LOG  2>&1           #--- join operation by bup restore files
                  if [ $? -eq 0 ]; then
                         message "  - Success : Restoring files in $APP_LOCATION finish, restore process continues ..."
                         message "  - Info    : the list of restored files can be seen at $REST_FILES_LOG "
                  fi
      fi
}


function validate_service { #--- Ensures an app is in place
   message "  - Check : Validating $APP_NAME Application is present "
   message "  - Running : Validating $APP_NAME Application or Filesystem Backup. "
   service $APP_NAME status
   if [ $? -eq 0 ]; then
         message "  - Check : $APP_NAME Successfully present "
         IS_SERVICE="0"  #--- "0" applications exists; "1" not available in the system
   else
         message "  - Check : $APP_NAME Not present or its a Filesystem backup"
         IS_SERVICE="1"  #--- "0" applications exists; "1" not available in the system
   fi
}


function get_app_status () {
    APP_STATUS=$( puppet resource service $APP_NAME | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
}


function appstop () { #--- Stops a service from puppet resorce command
   validate_service
   if [ "$IS_SERVICE" = "0" ]; then
           get_app_status
           case $APP_STATUS in
           "running")
                 service $APP_NAME stop
                 get_app_status
                 if [ "$APP_STATUS" = "stopped" ]; then
                          message "  - Success : $APP_NAME Service status is \"stop\""
                 else
                          message "  - Error : $APP_NAME stop signal no finish status is \"Unknow\""
                          pushlogs "error"
                          exit "$SERVICE_STOP_FAILED"    # send the status that will be interpreted as error in
                 fi
           ;;
           "stopped")
                 message "  - Success : $APP_NAME server status is already \"stopped\""
           ;;
           esac
   else
           message "  - Info : $APP_NAME Is not a Service, not present or Filesystem Backup"
   fi
}


function appstart () { #--- Stops a service from puppet resorce command
    get_app_status
    case $APP_STATUS in
    "running")          # --- weird and barely imposible status but anyway I left as it is.
            #---service $APP_NAME start
            service $APP_NAME restart
            get_app_status
            if [ "$APP_STATUS" = "running" ]; then
                          rstfls=$( "$BUP_CMD" -d $BKP_APP_DIR join $BUP_NAME | tar -tf - | wc -l )
                          message "  - Success : $APP_NAME Service status is \"running\""
                          message "  - Success : $APP_NAME Restore process concluded succesfully applications \"running\""
                          message "  - Info    : $APP_NAME Total files restored: $rstfls "
                          pushlogs "success"
            else
                          message "  - Error : $APP_NAME Running signal not successful status is \"Unknow\""
                          pushlogs "error"
                          exit "$SERVICE_START_FAILED"    #--- App didn't restart succesfully
            fi
    ;;
    "stopped")
            service $APP_NAME start
            get_app_status
            if [ "$APP_STATUS" = "running" ]; then
                           message "  - Success : $APP_NAME server status is \"running\""
                           message "  - Operations : Running Puppet Agent to apply configurations to $APP_NAME   "
                           puppet agent -t 2>&1    #TODO  ===== set cases to restart different applications.
            else
                           message "  - Error : $APP_NAME Running signal not successful status is \"Unknow\""
                           pushlogs "error"
                           exit "$SERVICE_START_FAILED"    # App didn't restart succesfully
            fi
    ;;
    esac
}


function mysqldstop (){ #--- reviews and stop if necessary mysql service
   get_app_status
   if [ -n "$APP_STATUS" ]; then
       case $APP_STATUS in
       "running")
             puppet resource service mysql ensure=stopped              #--- /usr/sbin/service mysql stop
             get_app_status
             if [ "$APP_STATUS" = "stopped" ]; then
                   message "  - Success : MySQL server status is \"stop\""
             else
                   message "  - Error : MySQL stop signal no finish status is \"Unknow\""
             fi
       ;;
       "stopped")
             message "  - Success : MySQL server status is \"stop\""
       ;;
       esac
   else
       message "  - Error : MySQL server no installed here"     #-- TODO see what to do in this case to fulfill the task
   fi
}


function mysqldstart(){ #--- reviews and stop if necessary mysql service
   APP_STATUS=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
   if [ -z "$APP_STATUS" ]; then
           message "  - Error : MySQL server no installed here"     #-- TODO see what to do in this case to fulfill the task
           exit "$MYSQL_NOT_INSTALLED"
   fi
   if [ $APP_STATUS = "stopped" ]; then
             service mysql start
             APP_STATUS=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
             if [ "$APP_STATUS" = "running" ]; then
                   message "  - Success : MySQL server status is \"running\""
             else
                   message "  - Error : MySQL running signal not success, status is Unknow"
                   pushlogs "error"
                   exit "$MYSQL_NOT_INSTALLED"
             fi
   fi
}


function startservices { #--- start services for a refered application
   case $dbtool in
         "mysqldump")
                  mysqldstart
                  mydumppush
         ;;
         "innobackupex")
                  #inno_restore
                  #mysqldstart
         ;;
   esac
   if [ $IS_SERVICE = "0" ]; then
      appstart
   fi
   if [ -d "$APP_LOCATION" ]; then
         restfiles=$( ls -lR $APP_LOCATION | wc -l )
         message "- Success: restored files-folders: $restfiles "
   fi
   message "- Info: Restored process concluded OK"
   pushlogs "success"              #--- send the the logs to the remote central backup storage instance (maestro)
}


function stopservices { #--- take care of the services used per application
   message "- Running: Performing Operations on the services implied on the restore of $APP_NAME "
   dbtool=$( cat $BKP_INFO | awk ' BEGIN { FS=":" } /^db_backup_tool/ {print $2}' | sed -e 's/^ "//'  -e 's/"$//' )
   message "- Info: DB backup tool used for $APP_NAME is $dbtool..."
   case $dbtool in
   "mysqldump")
         appstop
   ;;
   "innobackupex")
         #mysqldstop
         #appstop
   ;;
   *)
         appstop
   ;;
   esac
}


function setfolders () { #--- will set the folders (new for restored, old to preserve current files)

   case $dbtool in
   "innobackupex")
          # mvsqlfold
   ;;
   "mysqldump")
          mvsqlfoldcp
   ;;
   esac
   mvappfold
}


function setlocals { #--- will work for local repo restore, setting values to point local and avoid a remote pull
   message "- Running: Validating local directory provided as repo  for $APP_NAME "
   message "- Running: Validating local dir $BKP_CONTENT repo "
   if [ -d "$BKP_CONTENT" ];then
           message "- Running: Validating bup dir $BKP_CONTENT repo "
           message "- Running: Validating bup repo "
           BKP_APP_DIR=$BKP_CONTENT                                            #--- points the repo as folder to next operations performed
           BKP_INFO=$( ls "${BKP_APP_DIR}/bkphist/${APP_NAME}_backup.info" )       #--- sets the path of the backup file info
           if [ -f "$BKP_INFO" ]; then
                  message "- Success: Data of backup $APP_NAME is available "
           else
                  message "- Error: Data of backup $APP_NAME isn't pulled complete, check the backup process "
                  exit 12
           fi
           "$BUP_CMD" -d $BKP_CONTENT ls -a
           if [ $? -eq 0 ]; then
                  message "- Success: Validations to local repo $APP_NAME OK "
                  message "- Success: Bup local repo $APP_NAME OK "
                  BUP_NAME=$("$BUP_CMD" -d $BKP_APP_DIR ls | cut -d"/" -f1)                   #--- gets the bup backup name from the repository
           fi
   else
           message "- Error: Validation to local repo not succed, not valid path"
           message "- Error: Error 6, bup repository not set in place"
           message "- Error: Not valid path, please verify your setup"
           exit "$BKP_CONTENT_DOESNT_EXIST"    #--- BKP_CONTENT doesnt exist
   fi
}

function setenvironment () {
   case $SC_MODE in
   "-p")
      pullfunc           #-- get the files and folders using RSYNC
      getbkinffill       #-- set the variables to perform the operations
      stopservices       #--- stop service specifically needed to perform the restore.
      setfolders
   ;;
   "-l")
      setlocals
      stopservices
      setfolders
   ;;
   esac
}


function setrestore () { #-- finalize the operation
   bupjoin #--- do the bup operations to restore files
   startservices
}


function main (){ #--- control and centralice the actions performed by this script
    set_bup_cmd
    message "- Running: Performing restore for $APP_NAME "
    message "- Running: Performing restore for $APP_NAME "
    setenvironment     #-- do the necessarily movent before the restore
    setrestore
}

main