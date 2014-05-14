# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# This file is shared between user_data build sequence and box bootstrap sequence.

function GetJson
{
 python -c "
import json
import os.path
import sys
 
if os.path.isfile('$1'):
   json_d=open('$1').read()
   data=json.loads(json_d)
   if '$2' in data.keys():
      print(data['$2'])
      print >> sys.stderr, '$1 - Found: $2 = \"'+data['$2']+'\"'
   else:
      print '$3'
      print >> sys.stderr, 'Key \"$2\" not found. Default value to \"$3\"'
else:
   print '$3'
   print >> sys.stderr, 'Warning! File \"$1\" was not found. Default value to \"$3\"'
"
}

# make sure that the passed in gitlink is a valid git repository url
function GitLinkCheck
{
   _LINK=$1
   if [ "$_LINK" = "" ] || [ "$_LINK" = "default" ] ; then
     # this is a default git url, return non-zero so the caller knows.
     return 2
   fi
   if [ "$(echo $_LINK | grep '://')" = "" ]
   then # Check scp link provided
      if [ "$(echo $_LINK | grep -ie '^.*:[a-z].*$')" = "" ]
      then
           echo "ERROR: $_LINK is not a scp valid format."
           return 1 
      else
           return 0
      fi
   else
      # validate we got a valid git URL
      _LINK_PROTOCOL=$(echo $_LINK | awk -F'://' '{printf $1}')
      if   [ "$_LINK_PROTOCOL" = "ssh" ]   ||
           [ "$_LINK_PROTOCOL" = "http" ]  ||
           [ "$_LINK_PROTOCOL" = "https" ] ||
           [ "$_LINK_PROTOCOL" = "git" ]   ||
           [ "$_LINK_PROTOCOL" = "file" ]  ||
           [ "$_LINK_PROTOCOL" = "SSH" ]   ||
           [ "$_LINK_PROTOCOL" = "HTTP" ]  ||
           [ "$_LINK_PROTOCOL" = "HTTPS" ] ||
           [ "$_LINK_PROTOCOL" = "GIT" ]   ||
           [ "$_LINK_PROTOCOL" = "FILE" ]  ; then
           return 0
       else
           echo "ERROR: $_LINK does not have a valid protocol for git"
           return 1 
       fi
   fi
}

# TODO: find if we can source meta.js values from facter since we
#  have all meta.js in facters now.

if [ -f /etc/environment ]
then
   . /etc/environment
fi


# vim:syntax=sh
