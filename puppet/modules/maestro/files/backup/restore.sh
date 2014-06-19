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

#--- Variables sets by call of restoreraid master to perfom the restore
appname="$1"                 #--- Application name; sets the name for the restore folder
sourfold="$2"                #--- Indicates the remote path of the folder to be restored
evtime=""                    #--- mobile set of time event 
bupapprepo=""                #--- Contains the bup app repository path.
ensapp=""                    #--- Contains an status value that shows app availability in the system
apphome=""                   #--- contains the App home folder
#--- Harcoded Variables
RESTBASEPATH="/mnt/restore"
APPRESTFOLD="$RESTBASEPATH/$appname"
LOGFILE="$RESTBASEPATH/$appname_restore.log"
RESTFILOG=$RESTBASEPATH/$appname"_restfiles.log"
DBDATADIR=$(grep datadir /etc/mysql/my.cnf | cut -d"=" -f2 | cut -d" " -f2)
SSHCNFNAM="forj-bck"         #--- name of ssh configuration located on ~/.ssh/config file
RRLOGFOLD="/mnt/backups/restorelogs/"                #--- Remote folder for the restore logs
#------------------------------------------------------------------------------------------------------------------

function setev() {  #--- sets on time the timestamp 
  evtime="$(date +%d/%m-%k:%M:%S)"
  tag=$1
  msg=$2
  if [ -z $tag ]; then
          evtime="$(date +%d/%m-%k:%M:%S)"
  else
          evtime="$(date +%d/%m-%k:%M:%S)"
          case $tag in
          "Warning")
                echo "  - $tag : $evtime : $msg" >> $LOGFILE
          ;;
          "Error")
                echo "  - $tag : $evtime : $msg" >> $LOGFILE
          ;;
          "Operations")
                echo "  - $tag : $evtime : $msg" >> $LOGFILE
          ;;
          "Success")
                echo "  - $tag : $evtime : $msg" >> $LOGFILE
          ;;
          "Info")
                echo "  - $tag : $evtime : $msg" >> $LOGFILE
          ;;
          esac
  fi      
}

function pushlogs () { #--- send the log files to the central backup station "maestro"
   flval=$1
   setev
   echo "  - Operations : $evtime : Sending log operation files to Remote central instance  $apphome  " >> $LOGFILE
   case $flval in
   "error")
         scp  $LOGFILE $SSHCNFNAM:$RRLOGFOLD
   ;;
   "success")
         scp  $LOGFILE $SSHCNFNAM:$RRLOGFOLD
         scp  $RESTFILOG $SSHCNFNAM:$RRLOGFOLD
   ;;
   esac
}

function ssh_cnf_chk{ #--- set check of the ssh configurations
   ssh -t $SSHCNFNAM 'exit'
   if [ $? -eq 0 ]; then
   	      setev
   	      echo "  - Success : $evtime : SSH configurations are correct and working OK  " >> $LOGFILE
   else
          setev
          echo "  - Error   : $evtime : SSH Configurations wrong or not set, verifi your setting in ~/.ssh/config ">> $LOGFILE
          pushlogs "error
          exit 11  #--- ssh error
   fi
}

function pullfunc { #--- will receive parameters and do the pull of an specific folder to perform the restore
   if [ -d $RESTBASEPATH ]; then
            setev
            echo "  - Operations : $evtime : Begin pull remote folder by  " >> $LOGFILE
            rsync -avz $SSHCNFNAM:$sourfold $APPRESTFOLD >> $LOGFILE 2>&1
            if [ $? -eq 0 ]; then
                   setev
                   echo "  - Success : $evtime : Folder synchronized with local $APPRESTFOLD created OK  " >> $LOGFILE
            else
                   setev
                   echo "  - Error   : $evtime : rsync operation fails, see log file errors ">> $LOGFILE
                   pushlogs "error
                   exit 1  #--- rsync error
	        fi
   else
            setev
            echo "  - Operations : $evtime : Local Folder $RESTBASEPATH created  " >> $LOGFILE
            mkdir -p  $RESTBASEPATH
            setev
            echo "  - Operations : $evtime : Begin pull remote folder by  " >> $LOGFILE
            rsync -avz $SSHCNFNAM:$sourfold $APPRESTFOLD >> $LOGFILE 2>&1
            if [ $? -eq 0 ]; then
                   setev
                   echo "  - Success : $evtime : Folder synchronized with local $APPRESTFOLD created OK  " >> $LOGFILE
            else
                   setev
                   echo "  - Error   : $evtime : rsync operation fails, see log file errors ">> $LOGFILE
                   pushlogs "error"
                   exit 1  #--- rsync error
	        fi
   fi
}

function getbkinffill { #--- Get back (the beatles Song... :) get the names of bkp and the path for the repo set
   wktransf="$(ls $APPRESTFOLD)"
   if [ -n "wktransf" ]; then
            bupapprepo=$(find $APPRESTFOLD -type d -path "*$wktransf/$appname" -type d)
            bkpname=$(bup -d $bupapprepo ls | cut -d"/" -f1)                #--- gets the bup backup name from the repository
   else
            echo "  - Error : $evtime : by some error I see no folder set of bup backup " >> $LOGFILE
            pushlogs "error"
            exit 2  #--- not listed folder for backup set
   fi
}

function get_home {  #---gets "path" and sets $apphome variable
   case $appname in
   "jenkins")
        apphome=$(cat /etc/default/jenkins | grep JENKINS_HOME | cut -d"=" -f2)
   ;; 
   "gerrit")
        apphome="/home/gerrit2"
   ;;
   esac
} 
###########---------- Block of mv folders  ------------#############################################################################################
 
function mvsqlfold {  #--- move the old mysql folder and creates a new one
   if [ -d $DBDATADIR ]; then 
          setev
          echo "  - Operations : $evtime : MYSQL app home folder will be moved to $DBDATADIR.old " >> $LOGFILE
          mv -f $DBDATADIR "$DBDATADIR.old"
          if [ $? -eq 0 ]; then
          	     echo "  - Success : $evtime : MYSQL old app home folder is now moved to $DBDATADIR.old " >> $LOGFILE
          	     echo "  - Operations : $evtime : New MYSQL app home folder will be created: $DBDATADIR " >> $LOGFILE
                 mkdir -p $DBDATADIR
                 if [ $? -eq 0 ];then
                     setev
                     echo "  - Success : $evtime : MYSQL app home new folder created " >> $LOGFILE
                     chown -R mysql:mysql $DBDATADIR 
                     setev
                     echo "  - Operations : $evtime : MYSQL app home permissions set to \"mysql\" user " >> $LOGFILE
                 fi    
          else
                 echo "  - Error : $evtime : MYSQL app not created, by some error; maybe permissions or path are not correct, please verify " >> $LOGFILE
          fi
   else
          setev
          echo "  - Info : $evtime : MYSQL app home folder not present, please read mysql manuals " >> $LOGFILE
          mkdir -p  $DBDATADIR              #--- default is "/var/lib/mysql"
          chown -R mysql:mysql $DBDATADIR
          setev
          echo "  - Info : $evtime : MYSQL app home folder was created and permissions set, but service isn't installed yet " >> $LOGFILE
   fi
}

function mvappfold { #--- set a copy of the app home dir and replace an empty app home folder
   get_home
   if [ -d "$apphome" ]; then           
           owner=$( stat -c %U $apphome )       #--- looks into 
           mv $apphome  $apphome".old"
           mkdir -p $apphome
           chown -R $owner:$owner $apphome
           if [ $? -eq 0 ]; then
                  setev
                  echo "  - Success : $evtime : Folder for app $apphome created OK  " >> $LOGFILE
                  echo "  - Success : $evtime : Owner for Folder for app $apphome set to $owner  OK  " >> $LOGFILE
           fi
   else
           setev
           echo "  - Error : $evtime : seems like folder $apphome isn't available to move " >> $LOGFILE
           setev
           echo "  - Operations : $evtime : Anyhow I'll create a new $apphome folder  " >> $LOGFILE
           mkdir -p $apphome
           if [ $? -eq 0]; then 
           	      setev
           	      echo "  - Success : $evtime : Folder for app $apphome created OK  " >> $LOGFILE
           	      setev
           	      echo "  - Operations : $evtime : Set permissions for new $apphome folder " >> $LOGFILE           	   
                  owner==$( bup -d $bupapprepo join $bkpname |tar -tf - -v | sed -n '1p' | awk ' { print $2 } ' | cut -d"/" -f1  )
                  if [ -n "$( getent passwd $owner )" ]; then 
                         chown -R $owner:$owner $apphome
                         setev
                  	     echo "- Success: $evtime user exists, setting permissions to new $apphome folder " >> $LOGFILE
                  else 
                         setev
                         echo "- Info: $evtime User not exists, to preserve permissions $owner will be created" >> $LOGFILE                         
                         useradd -p $( mkpasswd -s $owner ) -s /bin/bash -d /home/$owner -m $owner                
                         if [ $? -eq 0 ]; then
                         	    setev
                  	            echo "- Success: $evtime user exists, setting permissions to new $apphome folder " >> $LOGFILE
                         	    chown -R $owner:$owner $apphome
                         	    setev
           	                    echo "  - Operations : $evtime : Set permissions for new $apphome folder " >> $LOGFILE
                         fi
                  fi
           else
                  setev
           	      echo "  - Error : $evtime : Folder for app $apphome not set; please check your User permissions  " >> $LOGFILE
           	      pushlogs "error"
           	      exit 5  #--- wrong permissions to set folders
           fi             
   fi
}

##############--------------- Block of Restoring Functions   ---------------##########################################################################
 
function inno_restore {     #--- restores the mysql Databases "#-- Innobackupex --#
   setev
   echo "  - Operations : $evtime : Unpacking DB files of set new $( ls -dS $bupapprepo/bkphist/DB*/* | sed -n '1p') " >> $LOGFILE
   echo "  - Operations : $evtime : DB set of files of to be restored ---: " >> $RESTFILOG
   tar -xvzf $( ls -dS $bupapprepo/bkphist/DB*/* | sed -n '1p') -C / >> $RESTFILOG 2>&1  #--- where tar.gz DB-bkps for this set reside.
   if [ $? -eq 0 ]; then 
   	      setev
          echo "- Success : $evtime DB folder unpacked, Performing innobackupex \"copy-back\" Operations:  " >> $LOGFILE
          dbdirunzip=$(find /mnt -mtime -1 -type f -name "ibdata1" -exec dirname {} \;)
          innobackupex --copy-back $dbdirunzip >> $LOGFILE 2>&1
                 
          if [ $? -eq 0 ]; then
                 chown -R mysql:mysql /var/lib/mysql               # --- DBtarset=  TODO use this variable for a set (array of backups tu choose
                 setev
                 echo "- Success : $evtime DB folder Permissions set on: /var/lib/mysql for mysql user and group.  " >> $LOGFILE
          else
                 setev
                 echo "- Error : $evtime : Innobackup copy-back operations Failed " >> $LOGFILE
                 pushlogs "error"
                 exit 8 #--- innobackup restore failed
          fi
   else
          setev
          echo "- Error : $evtime : DB Folder unsuccesfully unpacked " >> $LOGFILE
          pushlogs "error"
          exit 7 #--- tar operations error for DB folder
   fi
}

function bupjoin { #--- Depends on getbkname function to be accomplished first
   if [ -d "$bupapprepo" ];then
          setev
          echo "  - Operations : $evtime : start the Restoring of files and folders in $apphome  " >> $LOGFILE
                              # - bup -d $bupapprepo join $bkpname | tar -tf -   #--- join operation by bup (list contents)
          echo "  - Operations : $evtime : List of restored files and folders in $apphome :  " >> $RESTFILOG
          bup -d $bupapprepo join $bkpname | tar  xvpf - -C / -v >$RESTFILOG  2>&1           #--- join operation by bup restore files
          if [ $? -eq 0 ]; then
                 setev
                 echo "  - Success : $evtime : Restoring files in $apphome finish, restore process continues ..." >> $LOGFILE
                 echo "  - Info    : $evtime : the list of restored files can be seen at $RESTFILOG "
          else
                 echo "  - Error : $evtime : Restoring files not concluded well, check your Filesystem permissions or space " >> $LOGFILE
                 pushlogs "error"
                 exit 4 #--- untar bup backup and place on app home fails
          fi
   else
          setev
          echo ". _______________________________________________________________ ."
          echo "  - Error : $evtime : by some error I got not set bupapprepo, variable its empty" >> $LOGFILE
          pushlogs "error"
          exit 6 #--- weird error where the bup repo is no set or created
   fi
}


############------------ block of services functions ------------###################################################################################

function ensrapp { #--- Ensures an app is in place
   puppet resource service $appname
   if [ $? -eq 0 ]; then
         echo "  - Check : $evtime : $appname Successfully present " >> $LOGFILE
         ensapp="0"  #--- "0" applications exists; "1" not available in the system
   else
         echo "  - Check : $evtime : $appname Not present " >> $LOGFILE
         ensapp="1"  #--- "0" applications exists; "1" not available in the system
   fi
}

function appstop () { #--- Stops a service from puppet resorce command
   ensrapp
   if [ "$ensapp" = "0" ]; then
           srvstat=$( puppet resource service $appname | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
                   #--- $(service $appname status | grep -iwo "stop\|not running\|running")
           case $srvstat in
           "running")
                      #---service $appname stop
                 puppet resource service $appname ensure=stopped
                 srvstat=$( puppet resource service $appname | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
                 if [ "$srvstat" = "stopped" ]; then
                          setev
                          echo "  - Success : $evtime : $appname Service status is \"stop\"" >> $LOGFILE
                 else 
                          setev
                          echo "  - Error : $evtime : $appname stop signal no finish status is \"Unknow\"" >> $LOGFILE
                          pushlogs "error"
                          exit 3    # send the status that will be interpreted as error in
                 fi
           ;;
           "stopped")
                 setev
                 echo "  - Success : $evtime : $appname server status is \"stop\"" >> $LOGFILE
           ;;
           esac
   else
           setev
           echo "  - Error : $evtime : $appname Service not stopped cause isn't installed here" >> $LOGFILE
   fi
}

function appstart () { #--- Stops a service from puppet resorce command 
    srvstat=$( puppet resource service $appname | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
                   #--- $(service $appname status | grep -iwo "stop\|not running\|running")
    case $srvstat in
    "running")          # --- weird and barely imposible status but anyway I left as it is.
            #---service $appname start
            puppet resource service $appname ensure=running
            srvstat=$( puppet resource service $appname | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
            if [ "$srvstat" = "running" ]; then
                          rstfls=$( bup -d $bupapprepo join $bkpname | tar -tf - | wc -l )
                          setev
                          echo "  - Success : $evtime : $appname Service status is \"running\"" >> $LOGFILE
                          echo "  - Success : $evtime : $appname Restore process concluded succesfully applications \"running\"" >> $LOGFILE
                          echo "  - Info    : $evtime : $appname Total files restored: $rstfls " >> $LOGFILE 
                          
                          pushlogs "success"
            else 
                          setev
                          echo "  - Error : $evtime : $appname Running signal not successful status is \"Unknow\"" >> $LOGFILE
                          pushlogs "error"
                          exit 9    # send the status that will be interpreted as error in start
            fi
    ;;
    "stopped")
            puppet resource service $appname ensure=running
            srvstat=$( puppet resource service $appname | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
            if [ "$srvstat" = "running" ]; then
                           setev
                           echo "  - Success : $evtime : $appname server status is \"running\"" >> $LOGFILE
                           if [ "$appname" = "gerrit" ]; then
                                          setev
                                          echo "  - Operations : $evtime : Running Puppet Agent to apply configurations to $appname :   " >> $LOGFILE
                                          puppet agent -t >> $LOGFILE 2>&1
                                          setev
                                          echo "  - Operations : $evtime : Restarting $appname to push configurations   " >> $LOGFILE
                                          service $appname restart
                                          #/home/gerrit2/review_site/bin/gerrit.sh restart >> $LOGFILE 2>&1 
                                          if [ $? -eq 0 ]; then 
                                                 setev
                                                 echo "  - Success : $evtime : $appname server restarted and \" It's running\"" >> $LOGFILE
                                                 echo "  - Success : $evtime : $appname Restore process concluded succesfully applications \"running\"" >> $LOGFILE
                                                 pushlogs "success"
                                          else
                                                 setev
                                                 echo "  - Error : $evtime : $appname Running signal not successful started" >> $LOGFILE
                                          fi
                           else
                                          setev
                                          echo "  - Operations : $evtime : Running Puppet Agent to apply configurations to $appname   " >> $LOGFILE
                                          puppet agent -t >> $LOGFILE 2>&1    #TODO  ===== set cases to restart different applications.
                           fi
            else 
                           setev
                           echo "  - Error : $evtime : $appname Running signal not successful status is \"Unknow\"" >> $LOGFILE
                           pushlogs "error"
                           exit 9    # send the status that will be interpreted as error in start               
            fi            
    ;;
    esac   
}


#--- grep datadir /etc/mysql/my.cnf         #dbbkstore=ls -dS $bupapprepo/bkphist/DB* | sed -n '1p'


function mysqldstop (){ #--- reviews and stop if necessary mysql service
                                                             #---sqlstat=$(/usr/sbin/service mysql status | grep -iwo "stop\|running")
   srvstat=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d","     -f1 | cut -d"'" -f2 )
   if [ -n "$srvstat" ]; then
       case $srvstat in
       "running")
             puppet resource service mysql ensure=stopped              #--- /usr/sbin/service mysql stop
             srvstat=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d","     -f1 | cut -d"'" -f2 )
             if [ "$srvstat" = "stopped" ]; then
                   setev
                   echo "  - Success : $evtime : MySQL server status is \"stop\"" >> $LOGFILE
             else 
                   setev
                   echo "  - Error : $evtime : MySQL stop signal no finish status is \"Unknow\"" >> $LOGFILE
             fi
       ;;
       "stopped")
             setev
             echo "  - Success : $evtime : MySQL server status is \"stop\"" >> $LOGFILE
       ;;
       esac
   else
       setev
       echo "  - Error : $evtime : MySQL server no installed here" >> $LOGFILE     #-- TODO see what to do in this case to fulfill the task
   fi
}  

function mysqldstart(){ #--- reviews and stop if necessary mysql service
                                                             #---sqlstat=$(/usr/sbin/service mysql status | grep -iwo "stop\|running")
   srvstat=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d","     -f1 | cut -d"'" -f2 )
   if [ -n "$srvstat" ]; then
       case $srvstat in
       "running")  #--- same story, this validation is almost impossible to happen but I left as it is
             service mysqld restart
             puppet resource service mysql ensure=running              #--- /usr/sbin/service mysql stop
             srvstat=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d","     -f1 | cut -d"'" -f2 )
             if [ "$srvstat" = "running" ]; then
                   setev
                   echo "  - Success : $evtime : MySQL server status is \"running\"" >> $LOGFILE
             else 
                   setev
                   echo "  - Error : $evtime : MySQL start not succed, status is \"Unknow\"" >> $LOGFILE
                   pushlogs "error"
                   exit 10
             fi
       ;;
       "stopped")
             puppet resource service mysql ensure=running
             srvstat=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d","     -f1 | cut -d"'" -f2 )
             if [ "$srvstat" = "running" ]; then
                   setev
                   echo "  - Success : $evtime : MySQL server status is \"running\"" >> $LOGFILE
             else 
                   setev
                   echo "  - Error : $evtime : MySQL running signal not success, status is \"Unknow\"" >> $LOGFILE
                   pushlogs "error"
                   exit 10
             fi    
       ;;
       esac
   else
       setev
       echo "  - Error : $evtime : MySQL server no installed here" >> $LOGFILE     #-- TODO see what to do in this case to fulfill the task
   fi
}  



############------------ Invoque control functions ------------###################################################################################

function startservices { #--- start services for a refered application
   case $appname in
   "gerrit")
         inno_restore
         mysqldstart 
         appstart
   ;;
   *)
         appstart
   ;;
   esac
}


function stopservices { #--- take care of the services used per application
   case $appname in
   "gerrit")
         mysqldstop 
         appstop
   ;;
   *)
         appstop
   ;;
   esac
}

function setfolders () { #--- will set the folders
   case $appname in
   "gerrit")
     mvsqlfold 
     mvappfold
   ;;
   *)
     mvappfold
   esac
}

function setenvironment () {
   pullfunc           #-- get the files and folders
   getbkinffill       #-- set the variables to perform the operations
   stopservices    #--- stop service specifically needed to perform the restore.
   setfolders 
}
   
function setrestore () { #-- finalize the operation
   bupjoin #--- do the bup operations to restore files
   startservices
}

	
#service mysql start
#service gerrit start

# gerrit.config : IP Address incorrect.
# mysql> delete from account_external_ids where account_id=3 and email_address='clarsonneur@gmail.com';
# Query OK, 1 row affected (0.00 sec)

# mysql> update account_external_ids set account_id=3 where account_id=5 and email_address='clarsonneur@gmail.com';

function main (){ #--- control and centralice the actions performed by this script
    setev
    echo "- Running: $evtime : Performing restore for $appname " >> $LOGFILE
    setenvironment     #-- do the necessarily movent before the restore                
    setrestore                                                             
}
#------
main 
