#!/usr/bin/env bash
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.

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

# restoreraid script:
#
# works with the boxes where "restore.sh" script will perform the restore of app local files
# US-ID: 1659

SC_MODE=$1                                  #--- script flag main choice to control the behavior and tasks performed by the script.
SALT_CMD=""                                 #--- which salt
## -------usefull variable block

NODES_LIST=""                               #--- array that contains the list of nodes with backups on the maestro server
APP_NAME=""                                 #--- get or sets the app name for use on a request or as parameter
NODE_NAME=""                                #--- get or sets the node name for use on a request or as parameter
APP_LIST=""                                 #--- get or sets the available list of applications with backups


## ------ harcoded variables ------------------------------------------------------------------------------------------------------
RESTORE_SH="/usr/lib/forj/sbin/restore.sh"  #--- remote path where the restore.sh is located
BKP_MAIN_DIR="/mnt/backups"                 #--- Path that by default contains the backups of the instances.
LOGDIR="$BKP_MAIN_DIR/restorelogs"
LOGFILE="$LOGDIR/restoreraider.log"         #--- set the path for the LOGFILE to restoreraid operations
BKPUSER="forj-bck"


#--- Error codes

SALT_NOT_INSTALLED=1
NODE_DOESNT_EXIST=2
APP_DOESNT_EXIST=3
INVALID_WEEK=4
BACKUPS_DOESNT_EXIST=5
NODE_NAME_IS_REQUIRED=6
APP_NAME_IS_REQUIRED=7


function Help() {
 BASE=$(basename $0)
 echo -e "Usage is $BASE [flag] <parameters>

         $BASE [-A || -a]  <NODE_NAME> <APP_NAME> [<WEEK_NUM>]    : App restore
         $BASE [-F || -f]  [<WEEK_NUM>]                           : Full-kit restore
         $BASE [-M || -m]  <NODE_NAME> [<WEEK_NUM>]               : Node restore, ie. review
         $BASE [-H || -h]                                         : Show help

         If you need to see more reference use $BASE --help
"
 exit 0
}

function manual() {
 BASE=$(basename $0)
 echo -e "Usage is $BASE [flag] <parameters>

         $BASE [-A || -a]  <NODE_NAME> <APP_NAME> [<WEEK_NUM>]    : App restore
         $BASE [-F || -f]  [<WEEK_NUM>]                           : Full-kit restore
         $BASE [-M || -m]  <NODE_NAME> [<WEEK_NUM>]               : Node restore, ie. review
         $BASE [-H || -h]                                         : Show help


\"A\" or \"a\"   -- App restore:

                This option restores an app.
                Mandatory parameter: NODE_NAME, node name, example ci
                                     APP_NAME, application name
                Optional: WEEK_NUM, if empty the default will be last backup week

                $BASE -A ci jenkins 2014-30
                $BASE -A jenkins


\"F\" or \"f\"   -- Full kit restore:

                This option performs the restoring of all the applications backed up from a kit.
                Optional: WEEK_NUM, if empty the default will be last backup week

                $BASE -F 2014-30
                $BASE -F


\"M\" or \"m\"   -- Node restore

                Restores all apps from a node.
                Mandatory parameter: NODE_NAME, node name
                Optional: WEEK_NUM, if empty the default will be last backup week

                $BASE -M ci 2014-30
                $BASE -M ci 2014-30


\"H\" or \"h\"   -- Help: Show this help, same behavior if non flag provided or a sintax error happened.




Parameters:

<APP_NAME>:     Mandatory; Application parameter on the \"-A\" option, you must provide the convention name of the application without spaces or capitals.

<WEEK_NUM>:     Optional; Backup week parameter [1 - 4], default: last backup week if not provided.

<NODE_NAME>:    Mandatory; Node name parameter on the \"-M\"  and \"-A\" option, examples: review, ci, util

<host_target>:  Optional; Restores in a different host (This is not tested yet).
  "
  exit
}

function message(){
  local logtime="$(date +%d/%m-%k:%M:%S)"
  local msg=$1
  re='^[0-9]+$'
  if [ -n "$msg" ] ; then
         echo "${logtime}: ${msg}"
         [ -f "$LOGFILE" ] && echo "${logtime}: ${msg}" >> $LOGFILE
  fi
}

function message_exit(){
  local msg=$1
  local exit_code=$2
  message $msg
  if [ -n "$exit_code" ] ; then
        exit $exit_code
  else
       exit 1
  fi
}

function set_salt_cmd(){
  hash salt 2>/dev/null || { echo >&2 message_exit "Error: salt is not installed.  Aborting." "$SALT_NOT_INSTALLED"; }
  SALT_CMD=$(which salt)
}

function mkLOGDIR {
    if [ ! -d $LOGDIR ] ; then
            mkdir -p $LOGDIR
            chown $BKPUSER:$BKPUSER $LOGDIR
    fi
    if [ ! -f $LOGFILE ]; then
           touch $LOGFILE
    fi
    # Make the log readable and writable by the group and others:
    chmod go+rw $LOGFILE
}

function get_nodes_list () { #--- get the list for node-folder(s)
    LOCAL_NODE=$1
    LOCAL_DOMAIN=$(echo "$(hostname --domain)")
    message "- Operations: Full-restore,or list retrieve list of hosts folders backup containers in progress"
    if [ -z $LOCAL_NODE ]; then
            NODES_LIST=($( find $BKP_MAIN_DIR -type d -name "*.${LOCAL_DOMAIN}" ))  #--- Will list all the folders listed with *.domain in the name
    else
            NODES_LIST=($( find $BKP_MAIN_DIR -type d -name "${LOCAL_NODE}.${LOCAL_DOMAIN}" ))  #--- Will list all the folders listed with *.domain in the name
    fi
}

function pushfunc {     #--- Calls the minion to run
    CURRENT_APP="$1"           #--- app name
    MINION_NAME="$2"           #--- minion name to use
    BKP_CONTENT="$3"         #--- Path of the backup source
    MINION_CMD="$RESTORE_SH -p $CURRENT_APP $BKP_CONTENT"
    RETURN_CODE=$( "$SALT_CMD" "$MINION_NAME" cmd.retcode "${MINION_CMD}")  #--- call the minion restore.sh script
    if [ "$RETURN_CODE" == "0" ]; then
                message "- Success:  Restore operation for $CURRENT_APP completed"
                message "- Success:  Restore operations for $CURRENT_APP completed OK"
    else
       case $RETURN_CODE in
       "1")
              message "- Error:  $CURRENT_APP Rsync failed "
              message "- Error:  Rsync operations for $CURRENT_APP restore failed, bup repository not set in place "
       ;;
       "2")
              message "- Error:  $CURRENT_APP Backup folders are not in place "
              message "- Error:  Backup folder for $CURRENT_APP not in place, no repo available to restore "
       ;;
       "3")
              message "- Error:  $CURRENT_APP cannot be stopped "
              message "- Error:  Application $CURRENT_APP can't be stopped to perform the repo restoring "
       ;;
       "4")
              message "- Error:  $CURRENT_APP tar failed "
              message "- Error:  Unpack operations for backup and file placing on $CURRENT_APP folder, failed "
       ;;
       "5")
              message "- Error:  $CURRENT_APP restore failed, wrong permissions "
              message "- Error:  Folder permissions not set for $CURRENT_APP restore "
       ;;
       "6")
              message "- Error:  $CURRENT_APP bup repo does not exits "
              message "- Error:  Bup repo does not exits, probably wrong pulled by the box "
       ;;
       "7")
              message "- Error:  $CURRENT_APP DB tar failed "
              message "- Error:  tar operations for $CURRENT_APP DB backup and folders, failed "
       ;;
       "8")
              message "- Error:  $CURRENT_APP innobackupex/mysqldump operations failed "
              message "- Error:  innobackupex/mysqldump operations failed for $CURRENT_APP DB restoring "
       ;;
       "9")
              message "- Error:  $CURRENT_APP startup failed "
              message "- Error:  Startup failed after restoring "
       ;;
       "10")
              message "- Error:  $CURRENT_APPMySQL startup failed "
              message "- Error:  MySQL startup failed after restoring "
       ;;
       "11")
              message "- Error:  $CURRENT_APP SSH, Wrong configurations "
              message "- Error:  Wrong configurations in the box $MINION_NAME cant pull files and folders "
       ;;
       "12")
              message "- Error:  $CURRENT_APP Backup files are not complete "
              message "- Error:  Backup, files set are not complete in verify your backup process "
       ;;
       esac
    fi
}

function execute_restore () { #--- search for the selected week set for the different cases
    FLAG=$1           #--- values could be F, A or M (and its variations)
    SEC_PARAM=$2
    TRD_PARAM=$3
    FRT_PARAM=$4
    case $FLAG in
    "A")
        NODE=$SEC_PARAM
        APP=$TRD_PARAM
        WEEK=$FRT_PARAM
        get_nodes_list $NODE
        if [ -z "${NODES_LIST}" ]; then
             message_exit "- ERROR : the node ${NODE} does not exists" "$NODE_DOESNT_EXIST"
        fi
        APP_NAME=($( ls ${NODES_LIST} | grep -x $APP))
        if [ -z "${APP_NAME}" ]; then
             message_exit "- ERROR : the application ${APP} does not exist" "$APP_DOESNT_EXIST"
        fi
        MINION_NAME=$(salt-key -L |grep $NODE)
        CURRENT_APP_DIR=$( find $NODES_LIST -type d -name "$APP_NAME" -exec du -ac --max-depth=0 {} \; | sed -n '1p' | awk ' { print $2 }')
        if [ -z $WEEK ]; then
                WEEKS_APP_LIST=($(find  $CURRENT_APP_DIR/* -maxdepth 0 -type d | sort -gr ))
        else
                WEEKS_APP_LIST=($(find  $CURRENT_APP_DIR/* -maxdepth 0 -type d -name "$WEEK"))
        fi
        if [ -z ${WEEKS_APP_LIST[0]} ]; then
                message_exit "- ERROR : the week selected ${WEEK} is not valid" "$INVALID_WEEK"
                
        fi
        pushfunc $APP_NAME $MINION_NAME ${WEEKS_APP_LIST[0]}
    ;;
    "F")
        WEEK=$SEC_PARAM
        get_nodes_list
        if [ -z "$( echo ${NODES_LIST} )" ]; then
                message_exit "- ERROR : Nodes to restore not found" "$BACKUPS_DOESNT_EXIST"
        fi
        for CURRENT_NODE in "${NODES_LIST[@]}"; do
               APP_NAME=($( ls $CURRENT_NODE ))  #--- Pending to create an Specialized function to do this TODO
               for CURRENT_APP in "${APP_NAME[@]}"; do
                       NODE_NAME=$( echo $CURRENT_NODE | awk ' BEGIN { FS="/" } { print $4} ' | awk ' BEGIN { FS="."} { print $1 }' )
                       MINION_NAME=$(salt-key -L |grep $NODE_NAME)
                       CURRENT_APP_DIR=$( find $CURRENT_NODE -type d -name "$CURRENT_APP" -exec du -ac --max-depth=0 {} \; | sed -n '1p' | awk ' { print $2 }')
                       if [ -z "$WEEK" ]; then
                               WEEKS_APP_LIST=($(find  $CURRENT_APP_DIR/* -maxdepth 0 -type d | sort -gr ))
                       else
                               WEEKS_APP_LIST=($(find  $CURRENT_APP_DIR/* -maxdepth 0 -type d -name "$WEEK" | sort -gr ))
                       fi
                       if [ -z "${WEEKS_APP_LIST[0]}" ]; then
                            message "- WARNING : there are not weeks to restore or the week selected ${WEEK} is not valid for the ${CURRENT_APP} application"
                            continue
                       fi
                       pushfunc $CURRENT_APP $MINION_NAME ${WEEKS_APP_LIST[0]}                     #--- call the function that links with the remote restore.sh in the boxes
               done;
        done;
    ;;
    "M")
        NODE=$SEC_PARAM
        WEEK=$TRD_PARAM
        get_nodes_list $NODE
        if [ -z "${NODES_LIST}" ]; then
             message_exit "- ERROR : The node ${NODE} does not exists" "$BACKUPS_DOESNT_EXIST"
        fi
        APP_NAME=($( ls ${NODES_LIST} ))  #--- Pending to create an Specialized function to do this TODO
        for CURRENT_APP in "${APP_NAME[@]}"; do
            MINION_NAME=$(salt-key -L |grep $NODE)
            CURRENT_APP_DIR=$( find $NODES_LIST -type d -name "$CURRENT_APP" -exec du -ac --max-depth=0 {} \; | sed -n '1p' | awk ' { print $2 }')
            if [ -z $WEEK ]; then
                    WEEKS_APP_LIST=($(find  $CURRENT_APP_DIR/* -maxdepth 0 -type d | sort -gr ))
            else
                    WEEKS_APP_LIST=($(find  $CURRENT_APP_DIR/* -maxdepth 0 -type d -name "$WEEK"))
            fi
            if [ -z ${WEEKS_APP_LIST[0]} ]; then
                message "- WARNING : there are not weeks to restore or the week selected ${WEEK} is not valid for the ${CURRENT_APP} application"
                continue
            fi
            pushfunc $CURRENT_APP $MINION_NAME ${WEEKS_APP_LIST[0]}
       done;
    ;;
    "L")
        get_nodes_list
        case $week in
        "all")
              if [ -n "${NODES_LIST}" ]; then
                      message " The list of applications and backups sets is the following : \n"
                      for i in "${NODES_LIST[@]}"; do
                           ##############TODO this NODE_NAME is not just he node name is the whole fqnd###################
                           NODE_NAME=$( echo $i | awk ' BEGIN { FS="/" } {print $4}' ) #---- set for header of the info
                           message "*** Hostname :  $NODE_NAME *** "
                           APP_LIST=($(ls $i))
                           for e in "${APP_LIST[@]}"; do
                                bklist=($( ls -rS $i/$e ))
                                if [ -n "${bklist}" ]; then
                                       message "  - Application: $e "
                                       indx=0
                                       for a in "${bklist[@]}"; do
                                           let "indx+=1"
                                           message "     $indx -  $a"
                                       done
                                else
                                       message "- Info : No backups available to list for APP: $e "
                                fi
                           done

                      done
              else
                      message_exit "- Info : No backups available to list" "$BACKUPS_DOESNT_EXIST"
              fi
        ;;
        "allp")
             message "not yet full implemented, work in progress"
        ;;
        "*")
             message "not yet full implemented, work in progress"
        ;;
        esac
    ;;
    esac
}

function main (){
    SC_MODE=$1
    SECOND_PARAM=$2
    THIRD_PARAM=$3
    FOURTH_PARAM=$4
    set_salt_cmd
    if [ -n "$SC_MODE" ]; then
           mkLOGDIR
           case $SC_MODE in
           "-A"|"-a")
                    message "- Operations: App restore"
                    if [ -z "$SECOND_PARAM" ]; then
                              message_exit "- ERROR: <NODE_NAME> parameter is required." "$NODE_NAME_IS_REQUIRED"
                    fi
                    if [ -z "$THIRD_PARAM" ]; then
                              message_exit "- ERROR: <APP_NAME> parameter is required." "$APP_NAME_IS_REQUIRED"
                    fi
                    if [ -z "$FOURTH_PARAM" ]; then
                              message "Restore for ${THIRD_PARAM} applications in progress"
                              message "Performing Operations to restore your data, please do not stop the process"
                              execute_restore "A" $SECOND_PARAM $THIRD_PARAM
                    elif [ -n "$FOURTH_PARAM" ]; then
                              message "Restore for ${THIRD_PARAM} application, on date $FOURTH_PARAM in progress"
                              message "Performing Operations to restore your data, please do not stop the process"
                              execute_restore "A" $SECOND_PARAM $THIRD_PARAM $FOURTH_PARAM
                    fi
           ;;
           "-F"|"-f")
                    message "- Operations: Full-kit restore"
                    if [ -z "$SECOND_PARAM" ]; then
                            message "Full-restore for all the nodes, in progress"
                            message "- Operations: Full restore automatic, Default last backup week set will be restored"
                            message "\n Performing Operations to restore your data, please dont stop the process \n"
                            execute_restore "F"
                    elif [ -n "$SECOND_PARAM" ]; then
                              message "- Info: full Selecting restore by specific date: $SECOND_PARAM "
                              execute_restore "F" $SECOND_PARAM
                    fi
          ;;
          "-M"|"-m")
                    message "- Operations: Node restore"
                    if [ -z "$SECOND_PARAM" ]; then
                              message_exit "- ERROR: <NODE_NAME> parameter is required." "$NODE_NAME_IS_REQUIRED"
                    fi
                    if [ -z "$THIRD_PARAM" ]; then
                              message "Restore for ${SECOND_PARAM} node in progress"
                              message "Performing Operations to restore your data, please do not stop the process"
                              execute_restore "M" $SECOND_PARAM
                    elif [ -n "$THIRD_PARAM" ]; then
                              message "Restore for ${SECOND_PARAM} node, on date $THIRD_PARAM in progress"
                              message "Performing Operations to restore your data, please do not stop the process"
                              execute_restore "M" $SECOND_PARAM $THIRD_PARAM
                    fi
          ;;
          "-H"|"-h"|"--help")
                   message "--- Showing Help ---"
                   manual
          ;;
          *)
                   message " \"$SC_MODE\" is non valid flag "
                   Help
          ;;
          esac
    else
          message "- Error :  Non Parameter specified"
          read
          Help
    fi
}

main $SC_MODE $2 $3 $4             #-- call to main function