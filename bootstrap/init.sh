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

# Script to implement the Maestro bootstrap


if [ "p$1" = p--emulate ]
then
   EMULATE=True
   shift
fi

if [ "$1" = "" ]
then
   echo "$0: Missing bootstrap root dir. Box bootstrap cancelled."
   exit 1
fi

if [ ! -d "$1" ]
then
   echo "$0: bootstrap root dir '$1' doesn't exist. Box bootstrap cancelled."
   exit 1
fi

BIN_PATH="$(cd $(dirname $0); pwd)"
BOX_BOOT_DIR="$1"

source $BIN_PATH/functions

# Load build.d files

mkdir -p $BOX_BOOT_DIR/bootstrap

for INC_FILE in $BIN_PATH/init.d/*.sh
do
  echo "Maestro boot init: Loading $INC_FILE"
  if [ "$EMULATE" = True ]
  then
     echo "$0: should load ${INC_FILE}..."
  else
     source $INC_FILE
  fi
  echo "Maestro boot init: $INC_FILE done."
done

BOOTSTRAP_REPOS="$(GetJson /meta-boot.js bootstrap)"

# By default, it bootstraps from Maestro repository.
BOOTSTRAP_PATH=$BOX_BOOT_DIR/git/maestro/bootstrap/maestro

if [ "$BOOTSTRAP_REPOS" != "" ]
then

   for REPO in $(echo "$BOOTSTRAP_REPOS" | sed 's/|/ /g')
   do  
      if [ -d $BOX_BOOT_DIR/$REPO ]
      then
         echo "$0: Added '$BOX_BOOT_DIR/$REPO' to the Box bootstrap list"
         BOOTSTRAP_PATH="$BOOTSTRAP_PATH $BOX_BOOT_DIR/$REPO"
      fi  
   done
else
   echo "$0: No additional bootstrap. Use single Maestro boostrap."
fi

if [ "$BOOTSTRAP_PATH" != "" ]
then
   BOOT_FILES="$(find $BOOTSTRAP_PATH -maxdepth 1 -type f -name \*.sh -exec basename {} \; | sort -u)"

   echo "Read boot script: "
   for BOOT_FILE in $BOOT_FILES
   do
      for DIR in $BOOTSTRAP_PATH
      do  
         if [ -x $DIR/$BOOT_FILE ]
         then
            echo "Maestro boot init repo: $DIR/$BOOT_FILE Starting..."
            if [ "$EMULATE" = True ]
            then
               echo "Maestro boot init repo: should start ${BOOT_FILE}..."
            else
               bash -x $DIR/$BOOT_FILE
            fi
            echo "Maestro boot init repo: $DIR/$BOOT_FILE executed."
         else
            echo "Maestro boot init repo: Error! $DIR/$BOOT_FILE was not executed. Check rights."
         fi  
      done
   done
else
   echo "Maestro boot init repo: Warning! No bootstrap defined. (BOOTSTRAP_PATH is empty)"
fi


