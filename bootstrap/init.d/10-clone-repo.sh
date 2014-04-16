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

# Implements a git clone capability requested by metadata variable 'repos'

REPOS="$(GetJson /meta-boot.js repos)"

if [ "$REPOS" != "" ]
then

   mkdir -p /opt/config/production/git
   chmod 2775 /opt/config/production/git
   _CWD=$(pwd)

   if [ "$GITBRANCH" != "" ]
   then
       GITBRANCH_FLAG="-b $GITBRANCH"
   fi

   for REPO in $(echo "$REPOS" | sed 's/|/ /g')
   do
      # REPO string is composed by link->name
      REPO_LINK="$(echo "$REPO" | awk -F"->" '{print $1}')"
      REPO_DIRNAME="$(basename $(echo "$REPO" | awk -F'->' '{print $2}'))"
      GitLinkCheck $REPO_LINK
      if [ $? -ne 0 ]
      then
         continue
      fi
      git clone $GITBRANCH_FLAG $REPO_LINK $REPO_DIRNAME
      if [ ! -d $REPO_DIRNAME ]
      then
         echo "ERROR! 20-clone-repo.sh: $REPO_LINK was not cloned to $REPO_DIRNAME"
         continue
      fi
      cd $REPO_DIRNAME
      git config core.autocrlf false
      cd $_CWD
   done
fi
