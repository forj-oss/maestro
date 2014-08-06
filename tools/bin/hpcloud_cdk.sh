#!/bin/bash

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
# Help to identify services available from hpcloud eroPlus

function usage()
{
 printf "Usage is :
$(basename $0) --help                                    This help.
$(basename $0) [options]                                 To printout the list of kits.
$(basename $0) [options] <prefix options> [kit-options]  To printout services available from the kit.
$(basename $0) [options] <prefix options> <actions>      Specific actions function on our kits.
            
where :
Common options are: ie [options]
--a <HPC_Account>               : Will use a different HPCloud Account to query. Default one is given by 'hpcloud account'.
--get-from-cache                : Will use the last call cache file to extract data.

Prefix options are: ie <prefix options>
--prefix <Prefix> or --last     : Will identify which kit to query. EroPlus Prefix is a string before -eroplus server name.
--yes with --last               : Will automatically select the last kit found, without confirmation.

Kit details options are: ie [kit-options]
Without any options, the script will printout all services an openstack blueprint may declare. There is no query to the kit.
So, the list provided may differ if openstack blueprint has changed.
Following options will limit output to options you will select.
--only-ip                       : will restrict the output to only list of IPs.
--log                           : will display ssh command to tail cloud-init.log on the server.

Specific actions functions options are: ie <actions>
--remove-kit                    : to remove a kit.
--ssh <eroplus|ci|review|utils> : wrapper to ssh to one identified server. Recognized server string is 'eroplus', 'ci', 'review', 'utils'
\n"
   exit 1
}

function KitList
{
 echo "Incomplete kits are listed with ()"
 for PREFIX in $(sed 's/ [0-9]*,/,/g' $CACHE_FILE | awk -F, '$1 ~ /-(ci|review|util|eroplus)$/ || $1 ~ /^(eroplus|maestro|ci|review|util)\./ { printf "%s\n",$1}' | sed 's/\(-[a-z]*\|[a-z]*\.\)//g' | sort -u )
 do
   COUNT="$(sed 's/ [0-9]*,/,/g' $CACHE_FILE | awk -F, '$1 ~ /'$PREFIX'-(ci|review|util|eroplus)$/ || $1 ~ /^(eroplus|maestro|ci|review|util)\.'$PREFIX'$/'| wc -l)"
   if [ "$COUNT" -eq 4 ]
   then
      RESULT="$RESULT $PREFIX "
   else
      RESULT="$RESULT $PREFIX($COUNT) "
   fi
 done
 echo $RESULT
}

function KitIPs
{
 for KIT in $*
 do
   echo "######## Servers for kit $KIT:" 
   cat $CACHE_FILE | awk -F, '$1 ~ /'$KIT-'/ || $1 ~ /\.'$KIT'( [0-9]*)*$/ { printf "%s-%s (%s)\n",$1,$2,$3 }' 
 done
}

if [ $# -eq 0 ]
then
   usage
fi

if [ "$(which hpcloud | grep "which: no hpcloup")" ]
then
   echo "hpcloud tool not found. Check your path, and hpcloud installation."
   exit 1
fi

CACHE_FILE=/tmp/$(basename $0).lst

OPTS=$( getopt -o h -l get-from-cache,ssh:,a:,prefix:,last,yes,remove-kit,only-ip,log,nono,go,abort -- "$@" )
if [ $? != 0 ]
then
    usage "Invalid options"
fi
eval set -- "$OPTS"

DISPLAY_ALL=True

while true ; do
    case "$1" in
        -h) 
            usage;;
        --last)
            LAST=True
            shift;;
        --yes)
            ANS=True
            shift;;
        --get-from-cache)
            CACHE=True
            shift;;
        --ssh) 
            HPCLOUD_SSH=$2
            shift;shift;;
        --a)
            HPC_ACCOUNT="-a $2"
            shift;shift;;
        --remove-kit)
            ACTION=KILLALL
            shift;;
        --prefix)
            PREFIX=$2
            shift;shift;;
        --only-ip)
            ONLY_IP_DISPLAY=True
            DISPLAY_ALL=False
            shift;;
        --log)
            LOG_DISPLAY=True
            DISPLAY_ALL=False
            shift;;
        --nono)
            NONO_ACTION=$ACTION
            NONO=True
            shift;;
        --go)
            NONO_ACTION=GO
            CACHE=True
            NONO=True
            shift;;
        --abort)
            NONO_ACTION=ABORT
            CACHE=True
            NONO=True
            shift;;
        -- )
            shift;;
        "")
           break;;
        *)
          echo "Internal issue. Option $1 not managed."
          exit 255;;
    esac
done

if [ ! -r $CACHE_FILE ] || [ "$CACHE" = "" ]
then
   echo "Querying..."
   hpcloud servers -d , -c name,public_ip,keyname $HPC_ACCOUNT > $CACHE_FILE
fi

if [ "$LAST" = True ]
then
   PREFIX="$(sed 's/ [0-9]*//g' $CACHE_FILE | awk -F, '$1 ~ /(-eroplus|maestro\..*|eroplus\..*)$/ { printf "%s\n",$1} ' | sed 's/\(-eroplus\|maestro\.\|eroplus\.\)//g' | head -n 1)"
   if [ "$ANS" != "True" ]
   then
      echo "Auto-selecting latest kit prefix name : '${PREFIX}'. Are you ok? [y/n]"
      read ANS
      if [ "$ANS" != y ] && [ "$ANS" != Y ]
      then
         echo "'$PREFIX' [1mNot[0m confirmed: You can use --prefix to select different one en particular.
List of existing kit prefix running on hpcloud:"
         KitList
         exit 0
      else
         echo "'$PREFIX' confirmed."
      fi
   else
       echo "Auto-selecting latest kit prefix name : '$PREFIX'"
   fi
fi

if [ "$NONO" = True ]
then
   case "$NONO_ACTION" in
     GO)
         if [ ! -f .nono_actions ]
         then
            echo "what? You need to tell me what you want me to do... ask me with 'kit help'."
            exit
         fi
         source .nono_actions
         rm -f .nono_actions
         DISPLAY_ALL=False
       ;;
     ABORT)
       if [ ! -f .nono_actions ]
       then
          echo "what? You need to tell me what you want me to do before aborting... want to know? 'kit help'."
          exit
       fi
       echo "ok. Aborted."
       rm -f .nono_actions
       exit
       ;;
     KILLALL)
       # Check if the kit was previously listed. to prevent errors
       echo "Please review the list of servers before killing the kit:"
       KitIPs $PREFIX
       echo "PREFIX='$PREFIX'
ACTION=$ACTION" > .nono_actions
       echo "Are you ok to remove those servers? tell me 'go' or 'abort it'. thank you." 
       exit
       ;;
     *)
       exit
       ;;
   esac
fi

if [ "${PREFIX}" = "" ]
then
   KitList
   exit 
fi
for KIT in $PREFIX
do
  if [ "$(awk -F, '$1 ~ /'${KIT}-eroplus'/ || $1 ~ /(eroplus|maestro)\.'${KIT}'( [0-9]*)*$/ ||
                   $1 ~ /'${KIT}-ci'/      || $1 ~ /ci\.'${KIT}'$/                          ||
                   $1 ~ /'${KIT}-review'/  || $1 ~ /review\.'${KIT}'$/                      ||
                   $1 ~ /'${KIT}-util'/    || $1 ~ /util\.'${KIT}'$/ '                      $CACHE_FILE | wc -l )" -eq 0 ]
  then 
     echo "Warning! Unable to found any kit name '${KIT}'."
  fi
done



if [ $DISPLAY_ALL = True ] || [ "$ONLY_IP_DISPLAY" = True ] 
then
   KitIPs $PREFIX
fi

if [ "$HPCLOUD_SSH" != "" ]
then
   case $HPCLOUD_SSH in
     eroplus|ci|review|utils)
       KEYNAME="$(awk -F, '$1 ~ /'${PREFIX}-$HPCLOUD_SSH'/ { print $3 }' $CACHE_FILE)"
       if [ ! -f ~/.hpcloud/keypairs/${KEYNAME}.pem ]
       then
          echo "key name '${KEYNAME}' is not configured in hpcloud. Use the following command to create your private key to use with this server:
hpcloud keypairs:private:add ${KEYNAME} <PathToYourPrivateKey>/${KEYNAME}.pem $HPC_ACCOUNT"
          exit 1
       fi
       if [ $HPCLOUD_SSH != "eroplus" ]
       then
          hpcloud servers:ssh ${PREFIX}-$HPCLOUD_SSH -k "$KEYNAME" $HPC_ACCOUNT
       else
          hpcloud servers:ssh "$ERO_NAME" -k "$KEYNAME" $HPC_ACCOUNT
       fi
       exit;;
     *)
       echo "Unrecognized server string '$HPCLOUD_SSH'"
       exit 1;;
  esac
fi

if [ "$ACTION" = "KILLALL" ]
then
   for KIT in $PREFIX
   do
     echo "Killing the kit $KIT"
     eval "$(cat $CACHE_FILE | awk -F, '$1 ~ /'${KIT}-'/ || $1 ~ /\.'${KIT}'( [0-9]*)*$/ { printf "hpcloud servers:remove \"%s\" '"$HPC_ACCOUNT"'\n",$1 }')" 
   done
   exit 
fi

for KIT in $PREFIX
do
   if [ "$DISPLAY_ALL" = True ]
   then
     echo "######## KIT: $KIT
hpcloud removal commands:"
cat $CACHE_FILE | awk -F, '$1 ~ /'${KIT}-'/ || $1 ~ /\.'${KIT}'( [0-9]*)*$/ { printf "hpcloud servers:remove \"%s\" '"$HPC_ACCOUNT"'\n",$1 }' 
   fi

   if [ "$DISPLAY_ALL" = True ]
   then
      ERO_IP="$(    awk -F, '$1 ~ /'${KIT}-eroplus'/ || $1 ~ /(eroplus|maestro)\.'${KIT}'( [0-9]*)*$/ { print $2 }' $CACHE_FILE)"
      ERO_NAME="$(  awk -F, '$1 ~ /'${KIT}-eroplus'/ || $1 ~ /(eroplus|maestro)\.'${KIT}'( [0-9]*)*$/ { print $1 }' $CACHE_FILE)"
      ERO_KEY="$(   awk -F, '$1 ~ /'${KIT}-eroplus'/ || $1 ~ /(eroplus|maestro)\.'${KIT}'( [0-9]*)*$/ { print $3 }' $CACHE_FILE)"
      CI_IP="$(     awk -F, '$1 ~ /'${KIT}-ci'/      || $1 ~ /ci\.'${KIT}'$/                          { print $2 }' $CACHE_FILE)"
      CI_KEY="$(    awk -F, '$1 ~ /'${KIT}-ci'/      || $1 ~ /ci\.'${KIT}'$/                          { print $3 }' $CACHE_FILE)"
      REVIEW_IP="$( awk -F, '$1 ~ /'${KIT}-review'/  || $1 ~ /review\.'${KIT}'$/                      { print $2 }' $CACHE_FILE)"
      REVIEW_KEY="$(awk -F, '$1 ~ /'${KIT}-review'/  || $1 ~ /review\.'${KIT}'$/                      { print $3 }' $CACHE_FILE)"
      UTIL_IP="$(   awk -F, '$1 ~ /'${KIT}-util'/    || $1 ~ /util\.'${KIT}'$/                        { print $2 }' $CACHE_FILE)"
      UTIL_KEY="$(  awk -F, '$1 ~ /'${KIT}-util'/    || $1 ~ /util\.'${KIT}'$/                        { print $3 }' $CACHE_FILE)"
      echo "
Services should be:"
      if [ "$ERO_IP" != "" ]
      then
         echo "EroPlus: '$ERO_NAME' (ssh ubuntu@$ERO_IP -o StrictHostKeyChecking=no -i ~/.hpcloud/keypairs/${ERO_KEY}.pem)
cloud-init.log         : ssh ubuntu@$ERO_IP -o StrictHostKeyChecking=no -i ~/.hpcloud/keypairs/${ERO_KEY}.pem tail -f /var/log/cloud-init.log
eroplus - PuppetMaster : http://$ERO_IP:3000
eroplus - UI           : http://$ERO_IP
"
      fi
      if [ "$CI_IP" != "" ]
      then
         echo "CI:      (ssh ubuntu@$CI_IP -o StrictHostKeyChecking=no -i ~/.hpcloud/keypairs/${CI_KEY}.pem)
cloud-init.log         : ssh ubuntu@$CI_IP -o StrictHostKeyChecking=no -i ~/.hpcloud/keypairs/${CI_KEY}.pem tail -f /var/log/cloud-init.log
ci - jenkins           : http://$CI_IP:8080
ci - zuul              : http://$CI_IP
"
      fi

      if [ "$REVIEW_IP" != "" ]
      then
         echo "Review:  (ssh ubuntu@$REVIEW_IP -o StrictHostKeyChecking=no -i ~/.hpcloud/keypairs/${REVIEW_KEY}.pem)
cloud-init.log         : ssh ubuntu@$REVIEW_IP -o StrictHostKeyChecking=no -i ~/.hpcloud/keypairs/${REVIEW_KEY}.pem tail -f /var/log/cloud-init.log
review - gerrit/git    : http://$REVIEW_IP
"
      fi
      if [ "$UTIL_IP" != "" ]
      then
         echo "Utils:   (ssh ubuntu@$UTIL_IP -o StrictHostKeyChecking=no -i ~/.hpcloud/keypairs/${UTIL_KEY}.pem)
cloud-init.log         : ssh ubuntu@$UTIL_IP -o StrictHostKeyChecking=no -i ~/.hpcloud/keypairs/${UTIL_KEY}.pem tail -f /var/log/cloud-init.log
utils -                : http://$UTIL_IP
"
      fi

   fi
done
if [ "$DISPLAY_ALL" = True ]
then
   echo "if keys are not available in ~/.hpcloud/keypairs, use hpcloud keypairs:add"
fi
