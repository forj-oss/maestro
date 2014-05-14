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
restbasepath="/mnt/restore"
apprestfold="$restbasepath/$appname"
logfile="$restbasepath/$appname_restore.log"
restfilog=$restbasepath/$appname"_restfiles.log"
DBdatadir=$(grep datadir /etc/mysql/my.cnf | cut -d"=" -f2 | cut -d" " -f2)
sshcnfnam="forj-bck"         #--- name of ssh configuration located on ~/.ssh/config file 
#------------------------------------------------------------------------------------------------------------------

function setev() {  #--- sets on time the timestamp 
  evtime="$(date +%d/%m-%k:%M:%S)"
}

function pullfunc { #--- will receive parameters and do the pull of an specific folder to perform the restore
   if [ -d $restbasepath ]; then
            setev
            echo "  - Operations : $evtime : Begin pull remote folder by  " >> $logfile
            rsync -avz $sshcnfnam:$sourfold $apprestfold >> $logfile 2>&1
            if [ $? -eq 0 ]; then
                   setev
                   echo "  - Success : $evtime : Folder synchronized with local $apprestfold created OK  " >> $logfile
            else
                   setev
                   echo "  - Error   : $evtime : rsync operation fails, see log file errors ">> $logfile
                   exit 1  #--- rsync error
	        fi
   else
            setev
            echo "  - Operations : $evtime : Local Folder $restbasepath created  " >> $logfile
            mkdir -p  $restbasepath
            setev
            echo "  - Operations : $evtime : Begin pull remote folder by  " >> $logfile
            rsync -avz $sshcnfnam:$sourfold $apprestfold >> $logfile 2>&1
            if [ $? -eq 0 ]; then
                   setev
                   echo "  - Success : $evtime : Folder synchronized with local $apprestfold created OK  " >> $logfile
            else
                   setev
                   echo "  - Error   : $evtime : rsync operation fails, see log file errors ">> $logfile
                   exit 1  #--- rsync error
	        fi
   fi
}

function getbkinffill { #--- Get back (the beatles Song... :) get the names of bkp and the path for the repo set
   wktransf="$(ls $apprestfold)"
   if [ -n "wktransf" ]; then
            bupapprepo=$(find $apprestfold -type d -path "*$wktransf/$appname" -type d)
            bkpname=$(bup -d $bupapprepo ls | cut -d"/" -f1)                #--- gets the bup backup name from the repository
   else
            echo "  - Error : $evtime : by some error I see no folder set of bup backup " >> $logfile
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
   if [ -d $DBdatadir ]; then 
          setev
          echo "  - Operations : $evtime : MYSQL app home folder will be moved to $DBdatadir.old " >> $logfile
          mv -f $DBdatadir "$DBdatadir.old"
          if [ $? -eq 0 ]; then
          	     echo "  - Success : $evtime : MYSQL old app home folder is now moved to $DBdatadir.old " >> $logfile
          	     echo "  - Operations : $evtime : New MYSQL app home folder will be created: $DBdatadir " >> $logfile
                 mkdir -p $DBdatadir
                 if [ $? -eq 0 ];then
                     setev
                     echo "  - Success : $evtime : MYSQL app home new folder created " >> $logfile
                     chown -R mysql:mysql $DBdatadir 
                     setev
                     echo "  - Operations : $evtime : MYSQL app home permissions set to \"mysql\" user " >> $logfile
                 fi    
          else
                 echo "  - Error : $evtime : MYSQL app not created, by some error; maybe permissions or path are not correct, please verify " >> $logfile
          fi
   else
          setev
          echo "  - Info : $evtime : MYSQL app home folder not present, please read mysql manuals " >> $logfile
          mkdir -p  $DBdatadir              #--- default is "/var/lib/mysql"
          chown -R mysql:mysql $DBdatadir
          setev
          echo "  - Info : $evtime : MYSQL app home folder was created and permissions set, but service isn't installed yet " >> $logfile
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
                  echo "  - Success : $evtime : Folder for app $apphome created OK  " >> $logfile
                  echo "  - Success : $evtime : Owner for Folder for app $apphome set to $owner  OK  " >> $logfile
           fi
   else
           setev
           echo "  - Error : $evtime : seems like folder $apphome isn't available to move " >> $logfile
           setev
           echo "  - Operations : $evtime : Anyhow I'll create a new $apphome folder  " >> $logfile
           mkdir -p $apphome
           if [ $? -eq 0]; then 
           	      setev
           	      echo "  - Success : $evtime : Folder for app $apphome created OK  " >> $logfile
           	      setev
           	      echo "  - Operations : $evtime : Set permissions for new $apphome folder " >> $logfile           	   
                  owner==$( bup -d $bupapprepo join $bkpname |tar -tf - -v | sed -n '1p' | awk ' { print $2 } ' | cut -d"/" -f1  )
                  if [ -n "$( getent passwd $owner )" ]; then 
                         chown -R $owner:$owner $apphome
                         setev
                  	     echo "- Success: $evtime user exists, setting permissions to new $apphome folder " >> $logfile
                  else 
                         setev
                         echo "- Info: $evtime User not exists, to preserve permissions $owner will be created" >> $logfile                         
                         useradd -p $( mkpasswd -s $owner ) -s /bin/bash -d /home/$owner -m $owner                
                         if [ $? -eq 0 ]; then
                         	    setev
                  	            echo "- Success: $evtime user exists, setting permissions to new $apphome folder " >> $logfile
                         	    chown -R $owner:$owner $apphome
                         	    setev
           	                    echo "  - Operations : $evtime : Set permissions for new $apphome folder " >> $logfile
                         fi
                  fi
           else
                  setev
           	      echo "  - Error : $evtime : Folder for app $apphome not set; please check your User permissions  " >> $logfile
           	      exit 5  #--- wrong permissions to set folders
           fi             
   fi
}

##############--------------- Block of Restoring Functions   ---------------##########################################################################
 
function inno_restore {     #--- restores the mysql Databases "#-- Innobackupex --#
   setev
   echo "  - Operations : $evtime : Unpacking DB files of set new $( ls -dS $bupapprepo/bkphist/DB*/* | sed -n '1p') " >> $logfile
   echo "  - Operations : $evtime : DB set of files of to be restored ---: " >> $restfilog
   tar -xvzf $( ls -dS $bupapprepo/bkphist/DB*/* | sed -n '1p') -C / >> $restfilog 2>&1  #--- where tar.gz DB-bkps for this set reside.
   if [ $? -eq 0 ]; then 
   	      setev
          echo "- Success : $evtime DB folder unpacked, Performing innobackupex \"copy-back\" Operations:  " >> $logfile
          innobackupex --copy-back /mnt/backup/ >> $logfile 2>&1 
          if [ $? -eq 0 ]; then
                 chown -R mysql:mysql /var/lib/mysql               # --- DBtarset=  TODO use this variable for a set (array of backups tu choose
                 setev
                 echo "- Success : $evtime DB folder Permissions set on: /var/lib/mysql for mysql user and group.  " >> $logfile
          else
                 setev
                 echo "- Error : $evtime : Innobackup copy-back operations Failed " >> $logfile
                 exit 8 #--- innobackup restore failed
          fi
   else
          setev
          echo "- Error : $evtime : DB Folder unsuccesfully unpacked " >> $logfile
          exit 7 #--- tar operations error for DB folder
   fi
}

function bupjoin { #--- Depends on getbkname function to be accomplished first
   if [ -d "$bupapprepo" ];then
          setev
          echo "  - Operations : $evtime : start the Restoring of files and folders in $apphome  " >> $logfile
                              # - bup -d $bupapprepo join $bkpname | tar -tf -   #--- join operation by bup (list contents)
          echo "  - Operations : $evtime : List of restored files and folders in $apphome :  " >> $restfilog
          bup -d $bupapprepo join $bkpname | tar  xvpf - -C / -v >$restfilog  2>&1           #--- join operation by bup restore files
          if [ $? -eq 0 ]; then
                 setev
                 echo "  - Success : $evtime : Restoring files in $apphome finish, restore process continues ..." >> $logfile
                 echo "  - Info    : $evtime : the list of restored files can be seen at $restfilog "
          else
                 echo "  - Error : $evtime : Restoring files not concluded well, check your Filesystem permissions or space " >> $logfile
                 exit 4 #--- untar bup backup and place on app home fails
          fi
   else
          setev
          echo ". _______________________________________________________________ ."
          echo "  - Error : $evtime : by some error I got not set bupapprepo, variable its empty" >> $logfile
          exit 6 #--- weird error where the bup repo is no set or created
   fi
}


############------------ block of services functions ------------###################################################################################

function ensrapp { #--- Ensures an app is in place
   puppet resource service $appname
   if [ $? -eq 0 ]; then
         echo "  - Check : $evtime : $appname Successfully present " >> $logfile
         ensapp="0"  #--- "0" applications exists; "1" not available in the system
   else
         echo "  - Check : $evtime : $appname Not present " >> $logfile
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
                          echo "  - Success : $evtime : $appname Service status is \"stop\"" >> $logfile
                 else 
                          setev
                          echo "  - Error : $evtime : $appname stop signal no finish status is \"Unknow\"" >> $logfile
                          exit 3    # send the status that will be interpreted as error in
                 fi
           ;;
           "stopped")
                 setev
                 echo "  - Success : $evtime : $appname server status is \"stop\"" >> $logfile
           ;;
           esac
   else
           setev
           echo "  - Error : $evtime : $appname Service not stopped cause isn't installed here" >> $logfile
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
                          setev
                          echo "  - Success : $evtime : $appname Service status is \"running\"" >> $logfile
            else 
                          setev
                          echo "  - Error : $evtime : $appname Running signal not successful status is \"Unknow\"" >> $logfile
                          exit 9    # send the status that will be interpreted as error in start
            fi
    ;;
    "stopped")
            puppet resource service $appname ensure=running
            srvstat=$( puppet resource service $appname | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d"," -f1 | cut -d"'" -f2 )
            if [ "$srvstat" = "running" ]; then
                           setev
                           echo "  - Success : $evtime : $appname server status is \"running\"" >> $logfile
                           if [ "$appname" = "gerrit" ]; then
                                          setev
                                          echo "  - Operations : $evtime : Running Puppet Agent to apply configurations to gerrit   " >> $logfile
                                          puppet agent -t >> $logfile 2>&1
                                          echo "  - Operations : $evtime : Restarting gerrit to push configurations   " >> $logfile
                                          /home/ubuntu/home/gerrit2/review_site/bin/gerrit.sh restart >> $logfile 2>&1 
                                          if [ $? -eq 0 ]; then 
                                                 setev
                                                 echo "  - Success : $evtime : $appname server restarted and \" It's running\"" >> $logfile
                                          else
                                                 setev
                                                 echo "  - Error : $evtime : $appname Running signal not successful started" >> $logfile
                                          fi   
                           fi
            else 
                           setev
                           echo "  - Error : $evtime : $appname Running signal not successful status is \"Unknow\"" >> $logfile
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
                   echo "  - Success : $evtime : MySQL server status is \"stop\"" >> $logfile
             else 
                   setev
                   echo "  - Error : $evtime : MySQL stop signal no finish status is \"Unknow\"" >> $logfile
             fi
       ;;
       "stopped")
             setev
             echo "  - Success : $evtime : MySQL server status is \"stop\"" >> $logfile
       ;;
       esac
   else
       setev
       echo "  - Error : $evtime : MySQL server no installed here" >> $logfile     #-- TODO see what to do in this case to fulfill the task
   fi
}  

function mysqldstart(){ #--- reviews and stop if necessary mysql service
                                                             #---sqlstat=$(/usr/sbin/service mysql status | grep -iwo "stop\|running")
   srvstat=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d","     -f1 | cut -d"'" -f2 )
   if [ -n "$srvstat" ]; then
       case $srvstat in
       "running")  #--- same story, this validation is almost impossible to happen but I left as it is
             puppet resource service mysql ensure=running              #--- /usr/sbin/service mysql stop
             srvstat=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d","     -f1 | cut -d"'" -f2 )
             if [ "$srvstat" = "running" ]; then
                   setev
                   echo "  - Success : $evtime : MySQL server status is \"running\"" >> $logfile
             else 
                   setev
                   echo "  - Error : $evtime : MySQL stop signal no finish status is \"Unknow\"" >> $logfile
             fi
       ;;
       "stopped")
             puppet resource service mysql ensure=running
             srvstat=$( puppet resource service mysql | grep ensure | awk ' BEGIN { FS=">" } { print $2} ' | cut -d","     -f1 | cut -d"'" -f2 )
             if [ "$srvstat" = "running" ]; then
                   setev
                   echo "  - Success : $evtime : MySQL server status is \"running\"" >> $logfile
             else 
                   setev
                   echo "  - Error : $evtime : MySQL running signal not success, status is \"Unknow\"" >> $logfile
             fi             
       ;;
       esac
   else
       setev
       echo "  - Error : $evtime : MySQL server no installed here" >> $logfile     #-- TODO see what to do in this case to fulfill the task
   fi
}  



############------------ Invoque control functions ------------###################################################################################

function startservices { #--- Oposite to stopservices
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

function pushlogs () { #---
   echo "  - Operations : $evtime : start the copy of log operation files to Remote central instance  $apphome  " >> $logfile   
   scp  $logfile $sshcnfnam:/mnt/backups
   scp  $restfilog $sshcnfnam:/mnt/backups

}	
#service mysql start
#service gerrit start

# gerrit.config : IP Address incorrect.
# mysql> delete from account_external_ids where account_id=3 and email_address='clarsonneur@gmail.com';
# Query OK, 1 row affected (0.00 sec)

# mysql> update account_external_ids set account_id=3 where account_id=5 and email_address='clarsonneur@gmail.com';

function main (){ #--- control and centralice the actions performed by this script
    setev
    echo "- Running: $evtime : Performing restore for $appname " >> $logfile
    setenvironment     #-- do the necessarily movent before the restore                
    setrestore                                                             
}
#------
main 