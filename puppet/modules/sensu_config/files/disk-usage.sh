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
# Disk percentage.
total_usedp_tmp_file=$(tempfile)

df | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $1 " " $2 " " $3 " " $4 " " $5 " " $6 }' | while read output;
do
  filesystem=$(echo $output | awk '{ print $1 }' )
  used=$(echo $output | awk '{ print $3 }' )
  available=$(echo $output | awk '{ print $4 }' )
  usedp=$(echo $output | awk '{ print $5}' | cut -d'%' -f1  )
  partition=$(echo $output | awk '{ print $6 }' )

  total_used=$((total_used + used))
  total_available=$((total_available + available))
  echo "$total_used $total_available" | awk '{print ($1/$2)*100}' > $total_usedp_tmp_file
done

total_usedp=$(cat $total_usedp_tmp_file)
echo "$total_usedp"

unlink $total_usedp_tmp_file