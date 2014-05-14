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
# This script will run 'runbkp' for each configuration files found for backup.
# We address the need to start 1 backup even if there is several application to back up on one host.

BKP_CONF=/etc/forj/*.conf

function Help
{
 echo "Usage is $0 [--help|--confdir <BackupConfDir>]
where:
help                         : Is this help
configs <File1> [File2[...]] : Identify list of conf files. 
script <ScriptToUse>         : Is the backup script to use. Note that we can use any other kind of script for looping on configs.
script-opts <Options>        : Script options to use. The last option added will be the configuration file to use."
}

function write_log
{
 echo "$(date +"%Y-%m-%d %H:%M:%S") ($(basename $0) $$) $1"
}

# Parse commandline options

if [ $# -eq 0 ]
then
   Help
   exit
fi

while [ $# -ne 0 ]
do
  FOUND=0
  case "$1" in
    "--configs")
      shift
      if [ ! -r "$1" ]
      then
         echo "$1 is not readable. File ignored."
      else
         BKP_CONF_FILES="$1"
      fi
      shift
      while [ $# -ne 0 ] && [ "$(echo "p$1" | grep "^p--")" != "" ]
      do
         if [ ! -r "$1" ]
         then
            echo "$1 is not readable. File ignored."
         else
            BKP_CONFMATCH="$BKP_CONF_FILES $1"
         fi
         shift
      done
      FOUND=1
      ;;
    "--script")
      shift
      SCRIPT="$1"
      FOUND=1
      shift;;
    "--script-opts")
      shift
      SCRIPT_OPTS="$1"
      FOUND=1
      break;;
    "--help")
      Help
      exit 
      ;;
  esac
  if [ $FOUND = 0 ]
  then
     echo "$1 is not a recognized option."
     Help
     exit 1
  fi
done

# Testing script configuration

if [ ! -x "$SCRIPT" ]
then
   echo "$SCRIPT is not executable."
fi

if [ "$BKP_CONF_FILES" = "" ]
then
   echo "At least, one configuration file is required. Use --configs option."
   exit 1
fi

# Main configuration loop
for CONF_FILE in $BKP_CONF_FILES
do
   write_log "Starting '$SCRIPT $SCRIPT_OPTS $CONF_FILE'"
   eval "$SCRIPT $SCRIPT_OPTS $CONF_FILE"
   write_log "'$SCRIPT $SCRIPT_OPTS $CONF_FILE' ended with return code: $?"
done
