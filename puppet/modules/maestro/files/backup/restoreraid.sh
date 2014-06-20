#!/bin/bash
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

## -------usefull variable block

fecha_bkp=""                                #--- Parameter to package an specific week-set from history backup
weekcont=""                                 #--- 
week_no=""                                  #--- contain the value for the selected week
bkpfoldlist=""                              #--- array that contains the folder list of bkp's
avhst=""                                    #--- array where to capture available host's bkp folder path
appname=""                                  #--- get or sets the app name for use on a request or as parameter
hstname=""                                  #--- get or sets the hostname for use on a request or as parameter
applist=""                                  #--- get or sets the available list of applications with backups
## ------ harcoded variables ------------------------------------------------------------------------------------------------------

RESTORE_SH="/usr/lib/forj/sbin/restore.sh"  #--- remote path where the restore.sh is located
MAINCONT="/mnt/backups"                     #--- Path that by default contains the backups of the instances.
CURRENTWEEK=$(date +'%Y-%W')                #--- Base for current week
SALTFILESERVBASE="/srv/salt"                #--- base for salt srv file server
YEAR=$(date +'%Y')                          #--- system current YEAR
SC_MODE=$1                                  #--- script flag main choice to control the behavior and tasks performed by the script.
EVTIME="$(date +%d/%m-%k:%M:%S)"            #--- setteable time to markup a timestamp for an event.
LOGDIR="$MAINCONT/restorelogs"
LOGFILE="$LOGDIR/restoreraider.log"       #--- set the path for the LOGFILE to restoreraid operations
#--- minion full qualified names (fqdn for boxes) ---------------------------------------------
MINIONLS=""   #($(salt-key -L |grep forj ))       #--- minion array for 
ci_fqdn=""    #$(salt-key -L | grep ci)
review_fqdn=""   #$(salt-key -L | grep review)
util_fqdn=""     #$(salt-key -L | grep util)
BKPUSER="forj-bck"
###
function Help() {
 BASE=$(basename $0)
 echo -e " Usage is $BASE [flag] <parameter>  : Eg   \e[1;20m $BASE -F -w 1 \e[0m  <--- (full-kit backup using week 1 set to restore)

         [flag] = [AFMH] (-w -i )  <parameter> = ( appname + week_no ) || ( appname + -w week_no + -i host_target) ... etc
         $BASE [-A || -a]  <app_name> [<week_no>] [<host_target>]      :App-Specific backup restore
         $BASE [-F || -f]  [<week_no>]                                 :Full-kit backup restore
         $BASE [-M || -m]  <hostname> <week_no>                        :Full-instance backup restore
         $BASE [-H || -h]  - no parameter -                            :Show manual
         $BASE [-L || -l] [ <app_name> || --all || --allapp]                      :list relevant information of backups
        If you need to see more reference use \e[1;20m $BASE -h \e[0m
"
 exit
}
function manual() {
 BASE=$(basename $0)
 echo -e " Usage is $BASE [flag] <parameter>  : Eg   \e[1;20m $BASE -F -w 1 \e[0m  <--- (full-kit backup using week 1 set to restore)

         [flag] = [AFMH] (-w -i )
         $BASE [-A || -a]  <app_name> [<week_no>] [<host_target>]    :App-Specific backup restore
         $BASE [-F || -f]  [<week_no>]                               :Full-kit backup restore
         $BASE [-M || -m]  <hostname> <week_no>                      :Full-instance backup restore
         $BASE [-H || -h]  - no parameter -                          :Show this manual
         $BASE [-L || -l] [ <app_name> || --all ]                      :list relevant information of backups
  [flag] List of Flags:

 \"A\" or \"a\"  -- App specific backup restore : This option performs an specific application backup restore, you must provide; app_name (application name) as
                                                  Mandatory paratemer, backup-week is optional default will be last week backup: host_target (IP or FQDN) to 
                                                  indicate where to restore the app, Default will be the host setup in maestro.
                                                   - To specify week_no provide the aditional flag -w together with -A or after appname, applies the same for host_target:
                                        
                                                      $BASE -Awi jenkins 1 16.168.1.25  --o--  $BASE -A jenkins -w 1 -i 16.168.1.25
                                                     
                                                      $BASE -Aw jenkins 1  --o-- $BASE -A jenkins -w 1                       <--- provides app and name
                                                 
                                                      $BASE -Ai jenkins 16.168.1.25  --o-- $BASE -A jenkins -i 16.168.1.25   <--- provides app and destiny host
                               
                                                      $BASE -A jenkins        < provides only app, the other used values will be default configured ones.

 \"F\" or \"f\"  -- Full kit backup restore set : This option performs the restoring of all the applications backed up from a kit parting as reference the
                                                  week number to set the full restore. by default last backups set by no specify value for week. (not mandatory).
                                                   - To specify other than default week:

                                                      $BASE -F 1  --o-- $BASE -F -w 1  --o-- $BASE -Fw  <--- the use of \"w\" it's optional and not mandatory


 \"M\" or \"m\"  -- Full instance backup restore: This option performs an instance backup restore; Mandatory parameters: an specific instance name conventions are:
                                                  \"ci, review, util ..\" as part of the hostname, Optional: The week set to be restored defaul is last week backup.
                                                   - To specify other than default week:

                                                      $BASE -M 16.168.1.25 -w 1  --o-- $BASE -Mw 16.168.1.25 1      <--- provides host and bkp-week

 \"L\" or \"l\"  -- List backups (information)  : This option allow the user to get usefull information about the list of available backups, applications, paths with different
                                                  options from an specific application passed as parameter to a full list of application passed as --all parameter, see below  
                                                  how to use:
                                                      $BASE -L jenkins                              <--- will show the list of backups for the specific "jenkins" application
                                                      $BASE -L --all                                <--- will list the existant applications and below the list of backups per 
                                                                                                         each app.
                                                      $BASE -L --allapp                             <--- will only list the Available Applications backedup

                               
 \"H\" or \"h\"  -- Help                        : Show this help, same behavior if non flag provided or a sintax error happened.

Parameters:
 <app_name>        : Mandatory; parameter on the \"-A\" option, this name will be search in the list of applications available to restore, you must provide the 
                     convention name of the application without spaces nor Capitals.

 <week_no>         : Optional; Provides the reference of the history list from an existant number of weeks stored [1 - 4], default: last week bkp if not provided
    
 <host_target>     : Optional; usefull if you need to provide a different host destiny than the default available.
 
 <hostname>        : Mandatory; provides reference of which instance set to be restore; default week bkp will be restored unless other be specified.
                   

Values (how to) use Eg:
                              $BASE -A jenkins -w 1 -i 12.168.1.25               (specific application and different than default target host)
                              $BASE -F 1                                         (full restore using week 1 as


  "
  exit
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function setev() {  #--- Sets timestamp
    EVTIME="$(date +%d/%m-%k:%M:%S)"
}

function mkLOGDIR {
    if [ -d $LOGDIR ] ; then
            if [ -f $MAINCONT/restorelogs/restoreraider.log ]; then
                    setev
                    echo "- Success: $EVTIME Log file validated, OK" >> $LOGFILE
            else
                    touch $LOGFILE
                    echo "- Operations: $EVTIME Log file created" >> $LOGFILE
            fi
    else
            mkdir -p $LOGDIR
            chown $BKPUSER:$BKPUSER $LOGDIR
            mkLOGDIR
    fi
}
#function pushdisp () {   #--- send the tar-specific host file to the correspondent target minion host file.
#  echo "push of app-tar file for backups in progress"
#   
#}

#function tarhostbkp()  { #--- package the list of paths into a file by specific
#  tarbsnam=$1
#  tarfiles=$2
#  tar -cvzf $MAINCONT/$tarbsnam.tar.gz ${tarfiles[@]}
#  if [ $? -eq 0 ]
#     mv  $MAINCONT/$tarbsnam.tar.gz $SALTFILESERVBASE/
#  fi 
#}

#function bkweeklist()  { #--- will seek,list and store and specific host-week array of paths
#  spweek=$2              #--- parameter for week folder to search
#  sphost=$1              #--- parameter for host
#  weekcont=($(find $MAINCONT -type d -path "*$sphost*$spweek"))
#  if [ -n ${weekcont} ]; then
#       tarhostbkp $sphost ${weekcont[@]} 
#  else
#       echo "- Error : $EVTIME : Setting up percona repository unsuccessful" >> $LOGFILE
#  fi       
#} 

#function synchroinst() { #--- will push the synchronization of maestro backups fold to instance folder
#  insnam=$1
#  
#}

#function bckpsort { #--- travel into minions array to retrieve a full set to restore
#     for i in ${MINIONLS[@]}; do 
#        if [ -n $( echo $i |grep maestro) ] ; then 
#              echo " salt master: $i" 
#              echo "specific operations not yet designed"
#        else
#              echo "- Begin: $EVTIME minion: $i backup-restore" 
#              find
#        fi
#     done;
#}

#--- set main
#function main () {
#   
#} 

function gethostlist () { #--- get the list for app-folder(s)
    echo "- Operations: $EVTIME Full-restore,or list retrieve list of hosts folders backup containers in progress" >> $LOGFILE     
    avhst=($( find $MAINCONT -type d -name "*io" ))  #--- Will list all the folders listed with io in the name
}

function getapplist () { #--- gets the list of available applications that have being at least backuped once 	
    appfold=$1
    echo "- Operations: $EVTIME Full-restore, retrieve list of applications backup containers in progress" >> $LOGFILE
    applist=($(ls $i))
}

function pushfunc {     #--- Calls the minion to run 
    appi="$1"           #--- app name
    hdes="$2"           #--- minion name to use
    bkcont="$3"         #--- Path of the backup source
    retcode=$( salt "$hdes" cmd.retcode "$RESTORE_SH $appi $bkcont")  #--- call the minion restore.sh script
    if [ "$retcode" == "0" ]; then
                setev
                echo "- Success: $EVTIME : Restore operation for $appi completed" >> $LOGFILE
    else
       case $retcode in 
       "1")
              setev
              echo "- Error: $EVTIME : Rsync operation for $appi restore failed, bup repository not set in place" >> $LOGFILE
       ;;
       "2")  
              setev
              echo "- Error: $EVTIME : Backup set folder for $appi not in place, no lrepo available to restore " >> $LOGFILE                
       ;;
       "3")
              setev
              echo "- Error: $EVTIME : Application $appi cannot be stopped to perform the repo restoring  " >> 	$LOGFILE
       ;;
       "4")
              setev
              echo "- Error: $EVTIME : tar operations for bup backup and place on $appi home folder, failed " >> $LOGFILE
       ;;
       "5")
              setev
              echo "- Error: $EVTIME : wrong permissions to set folders for $appi home folder, failed " >> $LOGFILE
       ;;
       "6")   setev
              echo "- Error: $EVTIME : bup $appi repo does not exits, probably wrong pulled by the box " >> $LOGFILE
       ;;
       "7")   setev
              echo "- Error: $EVTIME : tar operations for $appi DB backup and place on mysql folder, failed " >> $LOGFILE
       ;;
       "8")   setev
              echo "- Error: $EVTIME : innobackupex operations, failed for $appi DB restoring " >> $LOGFILE
       ;;
       "9")   setev
              echo "- Error: $EVTIME : Starting, failed for $appi After restoring " >> $LOGFILE
       ;;       
       "10")  setev
              echo "- Error: $EVTIME : Starting, failed for MySQL server After restoring " >> $LOGFILE
       ;;
       "11")  setev
              echo "- Error: $EVTIME : SSH, Wron configurations in the box " >> $LOGFILE
       ;;
       esac
    fi
}


function getlist () { #--- search for the selected week set for the different cases
    flag=$1           #--- values could be F, A or M (and its variations) 
    comodin=$2
    case $flag in
    "F")
        if [ -z $comodin ]; then   #--- full restore without parameters (last backup set)
               gethostlist          
               if [ -n "$( echo ${avhst[@]} )" ]; then  
                      for i in ${avhst[@]}; do
                           appname=($( ls $i ))  #--- Pending to create an Specialized function to do this TODO
                           for appi in ${appname[@]}; do
                                   hstname=$( echo $i | awk ' BEGIN { FS="/" } { print $4} ' | awk ' BEGIN { FS="."} { print $1 }' )
                                   hostdest=$(salt-key -L |grep $hstname)
                                   mfpath=$( find $MAINCONT -type d -name "$appi" -exec du -ac --max-depth=0 {} \; | sed -n '1p' | awk ' { print $2 }') 
                                   bkhlist=($(find  $mfpath/* -maxdepth 0 -type d -name "*$YEAR*" | sort -gr ))
                                   #bkpfoldlist=($( find $MAINCONT -type d  -path "*$CURRENTWEEK" ))
                                   pushfunc $appi $hostdest ${bkhlist[0]}                     #--- call the function that links with the remote restore.sh in the boxes
                           done; 
                      done;
               else 
                      echo "- Info : $EVTIME the array of backups it's empty" >> $LOGFILE
                      exit 3                                  
               fi   
        # elif  ##--- pending TODO specific validations for different cases          
        fi 
    ;;
    "L")
        gethostlist
        case $comodin in
        "all")
              if [ -n "$( echo ${avhst[@]} )" ]; then
                      echo " The list of applications and backups sets is the following : \n" 
                      for i in ${avhst[@]}; do
                           hstname=$( echo $i | awk ' BEGIN { FS="/" } {print $4}' ) #---- set for header of the info
                           echo "*** Hostname :  $hstname *** "
                           getapplist $i
                           for e in ${applist[@]}; do
                                bklist=($( ls -rS $i/$e ))
                                if [ -n ${bklist[@]} ]; then
                                       echo "  - Application: $e "
                                       indx=0
                                       for a in ${bklist[@]};do
                                           let "indx+=1"
                                           echo "     $indx -  $a"
                                       done
                                else
                                       echo "- Info : $EVTIME No backups available to list for APP: $e " >> $LOGFILE
                                fi
                           done 
                           
                      done
              else
                      echo "- $EVTIME : No backups available to list at this time"
                      echo "- Info : $EVTIME No backups available to list" >> $LOGFILE
                      exit 3
              fi
        ;;
        "allp")
             echo "not yet full implemented, work in progress"
        ;;
        "*")
             echo "not yet full implemented, work in progress"
        ;;
        esac 
    ;;    
    # mfpath=$1
    #bkhs=$(find  $mfpath/* -maxdepth 0 -type d -name "*$YEAR*" | wc -l)
    # "start backup history check ---"
    #if [ $daycheck == $(date +%u) ] ; then
    #      if (( $bkhs > $Wcheck )) ; then
    #         bkhlist=($(find  $mfpath/* -maxdepth 0 -type d -name "*$YEAR*" | sort -gr ))
    #         rm -rf ${bkhlist[$Wcheck]}
    #         #find $MAINCONT -name "*$(( $(date +'%V') - 1))*.tar.gz"
    #      fi
    #fi
    esac
}

#
# mfpath=$( find $MAINCONT -type d -name "$appsnm" -exec du -ac --max-depth=0 {} \; | sed -n '1p' | awk ' { print $2 }' )
function main (){
    sec_param=$2 
    ter_param=$3
    if [ -n "$SC_MODE" ]; then
           mkLOGDIR
	       case $SC_MODE in
	       "-A"|"-a"|"-Aw"|"-Ai"|"-Awi")
	               #validins  ## retrieve values from the user; not in use now
	               #printvals ## print values
	               echo "option App-restore"
	       ;;
	       "-F"|"-f"|"-Fw")  ## FullBackup case "Beggining backup running at : $mydate " >> $LOGFILE
	                setev
	                echo "- Operations: $EVTIME option Full-restore, validation in progress" >> $LOGFILE
                    if [ -z "$sec_param" ]; then 
                            if [ "$SC_MODE" == "-F" ] || [ "$SC_MODE" == "-f" ]; then 
                                           sec_param="F"
                                           echo "Full-restore, in progress"
                                           setev
                                           echo "- Operations: $EVTIME Full restore automatic, Default last backup week set will be restored" >> $LOGFILE
                                           echo "\n Performing Operations to restore your data, please dont stop the process \n" 
                                           getlist $sec_param
                            elif [ "$SC_MODE" = "-Fw" ]; then
                                           echo "- Error: $EVTIME no set of backup seleted" >> $LOGFILE
	                                       echo "\n no Week chosen of Backup set to restore "
                                           read
                                           Help
                            fi
                    elif [ -n "$sec_param" ]; then
                              if [ "$SC_MODE" == "-F" ] || [ "$SC_MODE" == "-f" ]; then
                                             case $sec_param in
                                             [1-4])
                                                echo "weekset choosen $sec_param"
                                                week_no="$sec_param" 
                                             ;;
                                             "-w")
                                                if [ -z "$ter_param" ]; then
                	                                    echo "- Error: $EVTIME no set of backup seleted" >> $LOGFILE
	                                                    echo "\n no Week chosen"
                                                        read
                                                        Help
                                                else
                                                        case $ter_param in
                                                        [1-4])
                                                           echo "weekset choosen $sec_param"
                                                            week_no="$ter_param" 
                                                        ;;  
                                                        *)  
                                                           echo "- Error: $EVTIME no set of backup seleted" >> $LOGFILE
                                                           echo "\n value out of range"
                                                           read
                                                           Help 
                                                        ;;
                                                        esac
                                                fi
                                             ;;
                                             esac       
                              elif [ "$SC_MODE" == "-Fw" ]; then
                                               case $sec_param in
                                               [1-4])
                                                  echo "weekset choosen $sec_param"
                                               ;;  
                                               *)  
                                                  setev
                                                  echo "- Error: $EVTIME no set of backup seleted" >> $LOGFILE
                                                  echo "\n value out of range"
                                                  read
                                                  Help
                                               ;;
                                               esac 
                              fi
                    fi
	                                   #--   sshconfig --> function removed
	                                   #verify_init
	                                   #CreateRBack         ## call the main function to perform the backup 
	      ;;
	      "-M"|"-m"|"-Mw")
	               #if [ -f "$params" ]; then
	               #    chkconff
	               #else
	               #    echo "- Error: $EVTIME Checking config file: Error"
	               #fi
	               echo "option Full-instance restore"
	      ;;
	      "-H"|"-h"|"--help")
                   echo "--- Showing Help ---"
                   manual
          ;;
          "-L"|"-l")
                   if [ -n "$sec_param" ]; then                
                          SC_MODE="L"
                          case $sec_param in                    
                          "--all" )                               #---  $BASE -L --all          
                                echo "I will list all the applications and its backups \n"    #--- TODO 
                                getlist $SC_MODE "all" 
                          ;;
                          "--allapp")                             #---  $BASE -L --allapp  
                                echo "will only list the applications"                   #--- TODO
                                # getlist $SC_MODE "allp"
                          ;;
                          *)                                       #---  $BASE -L  <app_name> and other cases #---TODO
                                echo "will list specific application backup information , set by name"
                                # getlist $SC_MODE $sec_paraml
                          ;;
                          esac
                   else                                       
                          echo "- Error: $EVTIME not parameter set for search Application to list" >> $LOGFILE
                   fi                                  
                   
          ;;        
          *)
                   echo " \"$SC_MODE\" is non valid flag "
                   Help
	      ;;
	      esac
    else
          echo "- Error : $EVTIME : Non Parameter specified"  >> $LOGFILE
          read
          Help
    fi
}

main $SC_MODE $2 $3             #-- call to main function 