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

if [ "$1" = "" ]
then
   echo "$0: Missing bootstrap root dir. Box bootstrap cancelled."
   exit 1
fi

if [ ! -f "$1" ]
then
   echo "$0: bootstrap root dir '$1' doesn't exist. Box bootstrap cancelled."
   exit 1
fi

BIN_PATH="$(cd $(dirname $0); pwd)"
BOOTSTRAP_DIR="$1"

# Load build.d files

mkdir -p $BOOTSTRAP_DIR/bootstrap

for INC_FILE in $BIN_PATH/init.d/*.sh
do
  echo "Maestro boot init: Loading $INC_FILE"
  source $INC_FILE
  echo "Maestro boot init: $INC_FILE done."
done

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
            echo "Maestro boot init: $DIR/$BOOT_FILE Starting..."
            bash -x $DIR/$BOOT_FILE
            echo "Maestro boot init: $DIR/$BOOT_FILE executed."
         else
            echo "Maestro boot init: Error! $DIR/$BOOT_FILE was not executed. Check rights."
         fi  
      done
   done
else
   echo "Maestro boot init: Warning! No bootstrap defined. (BOOTSTRAP_PATH is empty)"
fi


