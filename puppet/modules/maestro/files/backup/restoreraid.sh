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

## -------usefull variable block

NODES_LIST=""                                    #--- array that contains the list of nodes with backups on the maestro server
APP_NAME=""                                  #--- get or sets the app name for use on a request or as parameter
NODE_NAME=""                                  #--- get or sets the node name for use on a request or as parameter
APP_LIST=""                                  #--- get or sets the available list of applications with backups
## ------ harcoded variables ------------------------------------------------------------------------------------------------------

RESTORE_SH="/usr/lib/forj/sbin/restore.sh"  #--- remote path where the restore.sh is located
BKP_MAIN_DIR="/mnt/backups"                     #--- Path that by default contains the backups of the instances.
LOGDIR="$BKP_MAIN_DIR/restorelogs"
LOGFILE="$LOGDIR/restoreraider.log"       #--- set the path for the LOGFILE to restoreraid operations
BKPUSER="forj-bck"
###
function Help() {
 BASE=$(basename $0)
 echo -e " Usage is $BASE [flag] <parameter>  : Eg   \e[1;20m $BASE -F -w 1 \e[0m  <--- (full-kit backup using week 1 set to restore)

         [flag] = [AFMH] (-w -i )  <parameter> = ( APP_NAME + WEEK_NUM ) || ( APP_NAME + -w WEEK_NUM + -i host_target) ... etc
         $BASE [-A || -a]  <NODE_NAME> <APP_NAME> [<WEEK_NUM>]                      :App-Specific backup restore
         $BASE [-F || -f]  [<WEEK_NUM>]                                 :Full-kit backup restore
         $BASE [-M || -m]  <NODE_NAME> [<WEEK_NUM>]                      :Full-instance backup restore
         $BASE [-H || -h]                                               :Show manual
         $BASE [-L || -l] [ <APP_NAME> || --all || --allapp]            :list relevant information of backups
        If you need to see more reference use \e[1;20m $BASE -h \e[0m
"
 exit
}

function manual() {
 BASE=$(basename $0)
 echo -e " Usage is $BASE [flag] <parameter>  : Eg   \e[1;20m $BASE -F -w 1 \e[0m  <--- (full-kit backup using week 1 set to restore)

         [flag] = [AFMH] (-w -i )
         $BASE [-A || -a]  <NODE_NAME> <APP_NAME> [<WEEK_NUM>]                    :App-Specific backup restore
         $BASE [-F || -f]  [<WEEK_NUM>]                               :Full-kit backup restore
         $BASE [-M || -m]  <NODE_NAME> [<WEEK_NUM>]                    :Full-instance backup restore ie. review
         $BASE [-H || -h]                                             :Show this manual
         $BASE [-L || -l] [ <APP_NAME> || --all ]                     :list relevant information of backups
  [flag] List of Flags:

 \"A\" or \"a\"  -- App specific backup restore : This option performs an specific application backup restore, you must provide; APP_NAME (application name) as
                                                  Mandatory paratemer, backup-week is optional default will be last week backup: host_target (IP or FQDN) to 
                                                  indicate where to restore the app, Default will be the host setup in maestro.
                                                   - To specify WEEK_NUM provide the aditional flag -w together with -A or after APP_NAME, applies the same for host_target:
                                        
                                                      $BASE -A jenkins 2014-30   <--- provides app and name
                                                 
                                                      $BASE -A jenkins           <--- provides only app, the other used values will be default configured ones.

 \"F\" or \"f\"  -- Full kit backup restore set : This option performs the restoring of all the applications backed up from a kit parting as reference the
                                                  week number to set the full restore. by default last backups set by no specify value for week. (not mandatory).
                                                   - To specify other than default week:

                                                      $BASE -F 2014-30           <--- FULL Restore of all the nodes for an specific week
                                                      
                                                      $BASE -F                   <--- FULL Restore of all the nodes using the last backup


 \"M\" or \"m\"  -- Full instance backup restore: This option performs an instance backup restore; Mandatory parameters: an specific instance name conventions are:
                                                  \"ci, review, util ..\" as part of the hostname, Optional: The week set to be restored defaul is last week backup.
                                                   - To specify other than default week:

                                                      $BASE -M 16.168.1.25 -w 2014-30  --o-- $BASE -Mw 16.168.1.25 2014-30      <--- provides host and bkp-week

 \"L\" or \"l\"  -- List backups (information)  : This option allow the user to get usefull information about the list of available backups, applications, paths with different
                                                  options from an specific application passed as parameter to a full list of application passed as --all parameter, see below  
                                                  how to use:
                                                      $BASE -L jenkins                              <--- will show the list of backups for the specific \"jenkins\" application
                                                      $BASE -L --all                                <--- will list the existant applications and below the list of backups per 
                                                                                                         each app.
                                                      $BASE -L --allapp                             <--- will only list the Available Applications backedup

 \"H\" or \"h\"  -- Help                        : Show this help, same behavior if non flag provided or a sintax error happened.

Parameters:
 <APP_NAME>        : Mandatory; parameter on the \"-A\" option, this name will be search in the list of applications available to restore, you must provide the 
                     convention name of the application without spaces nor Capitals.

 <WEEK_NUM>         : Optional; Provides the reference of the history list from an existant number of weeks stored [1 - 4], default: last week bkp if not provided
    
 <host_target>     : Optional; usefull if you need to provide a different host destiny than the default available.
 
 <hostname>        : Mandatory; provides reference of which instance set to be restore; default week bkp will be restored unless other be specified.
                   

Values (how to) use Eg:
                              $BASE -A jenkins -w 1 -i 12.168.1.25               (specific application and different than default target host)
                              $BASE -F 1                                         (full restore using week 1 as


  "
  exit
}

function message(){
  local logtime="$(date +%d/%m-%k:%M:%S)"
  local msg=$1
  [ -n "$msg" ] && echo "${logtime}: ${msg}"
  [ -f "$LOGFILE" ] && echo "${logtime}: ${msg}" >> $LOGFILE
}

function mkLOGDIR {
    if [ -d $LOGDIR ] ; then
            if [ -f $BKP_MAIN_DIR/restorelogs/restoreraider.log ]; then
                    message "- Success: Log file validated, OK"
            else
                    touch $LOGFILE
                    message "- Operations: Log file created"
            fi
    else
            mkdir -p $LOGDIR
            chown $BKPUSER:$BKPUSER $LOGDIR
            mkLOGDIR
    fi
}

function get_nodes_list () { #--- get the list for node-folder(s)
    LOCAL_NODE=$1
    LOCAL_DOMAIN=$(echo "$( facter | grep domain | sed s/'domain => '//g)")
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
    RETURN_CODE=$( salt "$MINION_NAME" cmd.retcode "$RESTORE_SH -p $CURRENT_APP $BKP_CONTENT")  #--- call the minion restore.sh script
    if [ "$RETURN_CODE" == "0" ]; then
                setev
                message "- Success:  Restore operation for $CURRENT_APP completed"
                message "- Success:  Restore operations for $CURRENT_APP completed OK"
    else
       case $RETURN_CODE in 
       "1")
              message "- Error:  Rsync operation for $CURRENT_APP restore failed, bup repository not set in place"
              message "- Error:  Rsync operations for $CURRENT_APP restore failed, bup repository not set in place"
       ;;
       "2")  
              message "- Error:  Backup set folder for $CURRENT_APP not in place, no repo available to restore "
              message "- Error:  Backup folder for $CURRENT_APP not in place, no repo available to restore "                
       ;;
       "3")
              message "- Error:  Application $CURRENT_APP cannot be stopped to perform the repo restoring  "
              message "- Error:  Application $CURRENT_APP can't be stopped to perform the repo restoring  "
       ;;
       "4")
              message "- Error:  tar operations for bup backup and place on $CURRENT_APP home folder, failed "
              message "- Error:  unpack operations for backup and file placing on $CURRENT_APP folder, failed "
       ;;
       "5")
              message "- Error:  wrong permissions to set folders for $CURRENT_APP home folder, failed "
              message "- Error:  folder not set for $CURRENT_APP restore, wrong permissions to set folders "
       ;;
       "6")
              message "- Error:  bup $CURRENT_APP repo does not exits, probably wrong pulled by the box "
              message "- Error:  bup $CURRENT_APP repo does not exits, probably wrong pulled by the box "
       ;;
       "7")
              message "- Error:  tar operations for $CURRENT_APP DB backups and FS folders, failed "
              message "- Error:  tar operations for $CURRENT_APP DB backup and folders, failed "
       ;;
       "8")
              message "- Error:  innobackupex/mysqldump operations, failed for $CURRENT_APP DB restoring "
              message "- Error:  innobackupex/mysqldump operations, failed for $CURRENT_APP DB restoring "
       ;;
       "9")
              message "- Error:  Starting, failed for $CURRENT_APP After restoring "
              message "- Error:  Starting, $CURRENT_APP failed  After restoring "
       ;;       
       "10")
              message "- Error:  Starting, failed for MySQL server After restoring "
              message "- Error:  Starting, MySQL server failed After restoring "
       ;;
       "11")
              message "- Error:  SSH, Wrong configurations in the box "
              message "- Error:  SSH, Wrong configurations in the box $MINION_NAME cant pull files and folders "
       ;;
       "12")
              message "- Error:  Backup, files for $CURRENT_APP set are not complete in the box "
              message "- Error:  Backup, files set are not complete in verify your backup process"
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
             message "- ERROR : the node ${NODE} does not exists"
             exit 3   
        fi
        APP_NAME=($( ls ${NODES_LIST} | grep -x $APP))
        if [ -z "${APP_NAME}" ]; then
             message "- ERROR : the application ${APP} does not exists"
             exit 3   
        fi
        MINION_NAME=$(salt-key -L |grep $NODE)
        CURRENT_APP_DIR=$( find $NODES_LIST -type d -name "$APP_NAME" -exec du -ac --max-depth=0 {} \; | sed -n '1p' | awk ' { print $2 }') 
        if [ -z $WEEK ]; then
                WEEKS_APP_LIST=($(find  $CURRENT_APP_DIR/* -maxdepth 0 -type d | sort -gr ))
        else
                WEEKS_APP_LIST=($(find  $CURRENT_APP_DIR/* -maxdepth 0 -type d -name "$WEEK"))
        fi      
        if [ -z ${WEEKS_APP_LIST[0]} ]; then
                message "- ERROR : the week selected ${WEEK} is not valid"
                exit 3
        fi
        pushfunc $APP_NAME $MINION_NAME ${WEEKS_APP_LIST[0]}
    ;;
    "F")
        WEEK=$SEC_PARAM
        get_nodes_list
        if [ -z "$( echo ${NODES_LIST} )" ]; then  
                message "- ERROR : there are not nodes for restore"
                exit 3
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
             message "- ERROR : the node ${NODE} does not exists"
             exit 3   
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
                      message "-  No backups available to list at this time"
                      message "- Info : No backups available to list"
                      exit 3
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
    if [ -n "$SC_MODE" ]; then
           mkLOGDIR
           case $SC_MODE in
           "-A"|"-a")
                    message "- Operations: restore option for specific application"
                    if [ -z "$SECOND_PARAM" ]; then
                              message "- ERROR: <NODE_NAME> parameter is required."
                              exit 1
                    fi
                    if [ -z "$THIRD_PARAM" ]; then
                              message "- ERROR: <APP_NAME> parameter is required."
                              exit 1
                    fi                       
                    if [ -z "$FOURTH_PARAM" ]; then 
                              message "Restore for ${SECOND_PARAM} applications in progress"
                              message "Performing Operations to restore your data, please do not stop the process" 
                              execute_restore "A" $SECOND_PARAM $THIRD_PARAM
                    elif [ -n "$FOURTH_PARAM" ]; then
                              message "Restore for ${SECOND_PARAM} application, on date $THIRD_PARAM in progress"
                              message "Performing Operations to restore your data, please do not stop the process" 
                              execute_restore "A" $SECOND_PARAM $THIRD_PARAM $FOURTH_PARAM
                    fi
           ;;
           "-F"|"-f")  ## FullBackup case "Beggining backup running at : $mydate "
                    message "- Operations: option Full-restore for all the nodes and all applications"
                    if [ -z "$SECOND_PARAM" ]; then 
                            message "Full-restore for all the nodes, in progress"
                            message "- Operations: Full restore automatic, Default last backup week set will be restored"
                            message "\n Performing Operations to restore your data, please dont stop the process \n" 
                            execute_restore "F"
                    elif [ -n "$SECOND_PARAM" ]; then
                              message "- Info: full Selecting restore by specificdate $SECOND_PARAM "
                              execute_restore "F" $SECOND_PARAM
                    fi
          ;;
          "-M"|"-m")
                    message "- Operations: option restore for specific node and all applications"
                    if [ -z "$SECOND_PARAM" ]; then
                              message "- ERROR: <NODE_NAME> parameter is required."
                              exit 1
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
          "-L"|"-l")
                   if [ -n "$SECOND_PARAM" ]; then                
                          SC_MODE="L"
                          case $SECOND_PARAM in                    
                          "--all" )                               #---  $BASE -L --all          
                                message "I will list all the applications and its backups \n"    #--- TODO 
                                execute_restore $SC_MODE "all" 
                          ;;
                          "--allapp")                             #---  $BASE -L --allapp  
                                message "will only list the applications"                   #--- TODO
                                # execute_restore $SC_MODE "allp"
                          ;;
                          *)                                       #---  $BASE -L  <APP_NAME> and other cases #---TODO
                                message "will list specific application backup information , set by name"
                                # execute_restore $SC_MODE $SECOND_PARAMl
                          ;;
                          esac
                   else                                       
                          message "- Error: not parameter set for search Application to list"
                   fi                                  
                   
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