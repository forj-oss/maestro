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


# This script implements the fog credential file required by MAESTRO to create the instance of a blueprint.

if [ -f "$INIT_FUNCTIONS" ]
then
   source $INIT_FUNCTIONS
else
   echo "Unable to load 'INIT_FUNCTIONS' ($INIT_FUNCTIONS). Script aborted."
   exit 1
fi


function check_var
{
 if [ "$1" = "" ]
 then
   echo "$2. Script aborted."
   exit 1
 fi
}

LORJ_ENABLED="$(GetJson /meta-boot.js lorj_enabled)"

if [ "$LORJ_ENABLED" = "" ]
then
   echo "No Lorj setting provided. Lorj configuration ignored."
   exit
fi

LORJ_FILE=/opt/config/lorj/accounts/cloud.yaml
if [ -e $LORJ_FILE ]
then
   echo "$LORJ_FILE exists. Not modified"
   exit
fi

LORJ_TMP_FILE="/tmp/lorj_cloud.yaml"
LORJ_TMP_KEY="/tmp/lorj_cloud.key"
# Do never print more than 4 lines waiting. Used by forj cli to detect the need to call test-box.
set +x
echo "forj-cli: lorj_tmp_file=$LORJ_TMP_FILE lorj_tmp_key=$LORJ_TMP_KEY flag_file=${LORJ_TMP_FILE}.sent"
echo "build.sh: Not supported."
echo "15-forj-lorj_cloud.sh: Waiting for $LORJ_TMP_FILE to exist.
On your workstation, your forj cli will need to send this file. If you have stopped forj cli, just restart it."
# ----------------------------------------

while [ ! -f ${LORJ_TMP_FILE}.sent ]
do
   sleep 5
done

if [ ! -f ${LORJ_TMP_FILE} ] || [ ! -f ${LORJ_TMP_KEY} ]
then
   echo "at least, '${LORJ_TMP_FILE}' or '${LORJ_TMP_KEY}' are not found. Lorj account setup ignored."
   exit
fi

if [ "$LORJ_ENABLED" = "false" ]
then
   if [ -f /opt/config/lorj/config.yaml ]
   then
      if [ "$(grep -e '[^#] *:lorj: ' /opt/config/lorj/config.yaml)" != "" ]
      then
         sed -i 's/\([^#] *:lorj:\).*$/\1 false/g' /opt/config/lorj/config.yaml
      else
         echo "  :lorj: false" > /opt/config/lorj/config.yaml
      fi
   else
      echo "---
:default:
  :lorj: false" > /opt/config/lorj/config.yaml
   fi
   echo "Lorj is disabled. To-re-enable it, update /opt/config/lorj/config.yaml"
fi

lorj_account_import.rb /opt/config/lorj "$(cat $LORJ_TMP_KEY)" ${LORJ_TMP_FILE} cloud.yaml

###########################################################################################

# vim: syntax=sh
