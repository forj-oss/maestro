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
# This script contains common functions for scripts.

LIGHTRED="[31;1m"
LIGHTGREEN="[32;1m"
LIGHTYELLOW="[33;1m"
BOLD="[1m"
DFL_COLOR="[0m"

function Exit
{
 if [ "$BUILD_DIR" != "" ] && [ -d $BUILD_DIR ]
 then
    rm -fr "$BUILD_DIR"
 fi
 exit $1
}

function Error
{
 echo "${LIGHTRED}ERROR${DFL_COLOR}: $2"
 Exit $1
}

function Info
{
 echo "${BOLD}INFO${DFL_COLOR}! $1"
}

function Warning
{
 echo "${LIGHTYELLOW}WARNING${DFL_COLOR}! $BOLD$1$DFL_COLOR"
}

MIME_SCRIPT=$BIN_PATH/build-tools/write-mime-multipart.py
