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
#
# Evaluate free system memory from Linux based systems.
#
# Date: 2007-11-12
# Author: Thomas Borger - ESG
# Date: 2012-04-02
# Modified: Norman Harman - norman.harman@mutualmobile.com
#
# The memory check is done with following command line:
# free -m | grep buffers/cache | awk '{ print $4 }'

# get arguments

while getopts 'w:c:hp' OPT; do
  case $OPT in
    w)  WARN=$OPTARG;;
    c)  CRIT=$OPTARG;;
    h)  hlp="yes";;
    p)  perform="yes";;
    *)  unknown="yes";;
  esac
done

# usage
HELP="
    usage: $0 [ -w value -c value -p -h ]

        -w --> Warning MB < value
        -c --> Critical MB < value
        -p --> print out performance data
        -h --> print this help screen
"

if [ "$hlp" = "yes" ]; then
  echo "$HELP"
  exit 0
fi

WARN=${WARN:=0}
CRIT=${CRIT:=0}

FREE_MEMORY=`free -m | grep buffers/cache | awk '{ print $4 }'`

if [ "$FREE_MEMORY" = "" ]; then
  echo "MEM UNKNOWN -"
  exit 3
fi

if [ "$perform" = "yes" ]; then
  output="free system memory: $FREE_MEMORY MB | free memory="$FREE_MEMORY"MB;$WARN;$CRIT;0"
else
  output="free system memory: $FREE_MEMORY MB"
fi

if (( $FREE_MEMORY <= $CRIT )); then
  echo "MEM CRITICAL - $output"
  exit 2
elif (( $FREE_MEMORY <= $WARN )); then
  echo "MEM WARNING - $output"
  exit 1
else
  echo "MEM OK - $output"
  exit 0
fi
