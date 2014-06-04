#!/bin/bash --norc
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
# This script implements the Bootstrap build for testing purpose.
# 
# ChL: Added Build configuration load.

BUILD_CONFIG=bld
CONFIG_PATH=. # By default search for configuration files on the current directory

# Those data have to be configured in a build configuration file
#FORJ_BASE_IMG=
#FORJ_FLAVOR=

BUILD_PREFIX=bld-maestro-
BUILD_SUFFIX=.forj.io
BUILD_IMAGE_SUFFIX=built

GITBRANCH=master

APPPATH="."
BIN_PATH="$(cd $(dirname $0); pwd)"
BUILD_SCRIPT=$BIN_PATH/$(basename $0)

BOOTHOOK=$BIN_PATH/build-tools/boothook.sh

declare -A META

function usage
{
 if [ "$1" != "" ]
 then
    Warning "$1"
 fi
 echo "$0 --box-name <BoxName> [--gitBranch <branch>/--gitBranchCur] [--build-conf-dir <confdir>] --build-config <config> | -h
Script to build a Box identified as <BoxName>. You can create an image or simple that box to test it.
It uses 'hpcloud' cli. You may need to install it.

The build configuration identified as <Config> will define where this box/image will be created. By default, it is fixed to 'master'.
You can change it with option --gitBranch or --gitBranchCur if your configuration file is tracked by a git repository.

Using --build-config [1m<Config>[0m(with or without --build-conf-dir) will load information about:
- BUILD_ID               : Optionally force to use a build ID.
- APPPATH                : Path to bootstrap files to use.
- FORJ_HPC_TENANTID       : HPCloud Project tenant ID used.
- FORJ_HPC_COMPUTE        : HPCloud compute service to use.
- FORJ_HPC_NETWORKING     : HPCloud networking service to use.
- FORJ_HPC_CDN            : HPCloud CDN service to use.
- FORJ_HPC_OBJECT_STORAGE : HPCloud Object storage service to use.
- FORJ_HPC_BLOCK_STORAGE  : HPCloud Block storage service to use.
- FORJ_HPC_DNS            : HPCloud Domain name service to use.
- FORJ_HPC_LOAD_BALANCER  : HPCloud Load balancer service to use.
- FORJ_HPC_MONITORING     : HPCloud Monitoring service to use.
- FORJ_HPC_DB             : HPCloud Mysql service to use.
- FORJ_HPC_REPORTING      : HPCloud Reporting service to use.
- FORJ_BASE_IMG          : HPCloud image ID to use.
- FORJ_FLAVOR            : HPCloud flavor ID to use.
- BOOTSTRAP_DIR          : Superseed default <BoxName> bootscripts. See Box bootstrap section for details.
                           

It will load this data from <confdir or .>/<BoxName>.[1m<Config>[0m.env file

Depending on the <config> data, you can build your box/image to different tenantID. one tenant for DEV, one tenant for PRO, etc...

To build your image, you need to be in the directory which have your <BoxName> as a sub directory. 

Box bootstrap:
==============

build.sh will create a user_data to boot your box as wanted.
To build it, build.sh will search for :
1. include 'boothook.sh' - Used to configure your hostname and workaround meta.js missing file.
2. check if <BoxName>/cloudconfig.yaml exist and add it.
3. build a 'boot box' shell script from <BoxName/bootstrap/{#}-*.sh. <BOOTSTRAP_DIR> will be merged with the default bootstrap dir. The merged files list are sorted by there name. if build found the same file name from all bootstrap directories, build.sh will include <BoxName>/bootstrap, then your BOOTSTRAP_DIR list.

Then build.sh will create a mime file which will be sent to the box with user-data feature.


Options details:
================
--box-name <BoxName>           : Defines the name of the box or box image to build.

--gitBranch <branch>           : The build will extract from git branch name. It sets the configuration build <config> to the branch name <branch>.
--gitBranchCur                 : The build will use the default branch current set in your git repo. It sets the configuration build <config> to the current git branch.

--build-conf-dir <confdir>     : Defines the build configuration directory to load the build configuration file. You can set FORJ_BLD_CONF_DIR. By default, it will look in your current directory.
--build-config <config>        : The build config file to load <confdir>/<BoxName>.<Config>.env. By default, uses 'master' as Config.

-h                             : This help

user-data bootstrap options:
============================
--boothook <boothookFile>      : Optionnal. By default, boothook file used is build/bin/build-tools/boothook.sh. Use this option to set another one.
--extra-bs-step <[Order:]File> : Add an extra user_data bootstrap step. This file in a specific 'Order' will be concatenated to the 'boot box' mime sequence, like BOOTSTRAP_DIR.

By default, the config name is 'master'. But <Config> can be set to the name of the branch thanks to --gitBranch, --gitBranchCur or from --build-config" 

 Exit 0
}


# ------------------------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------------------------

# Load build.d files

for INC_FILE in $BIN_PATH/build.d/*.d.sh
do
  source $INC_FILE
done

# Checking build options

if [ $# -eq 0 ]
then
   usage
fi

OPTS=$(getopt -o h -l box-name:,build-conf-dir:,gitBranch:,gitBranchCur,build-config:,gitLink:,debug,meta:,meta-data:,boothook:,extra-bs-step: -- "$@" )
if [ $? != 0 ]
then
    usage "Invalid options"
fi
eval set -- "$OPTS"

while true ; do
    case "$1" in
        -h) 
            usage;;
        --debug)
            set -x
            shift;;
        --gitBranch)
            BRANCH=$2
            GITBRANCH="$(git branch --list $BRANCH)"
            if [ "$GITBRANCH" = "" ]
            then
               Error 1 "Branch '$BRANCH' does not exist. Use 'git branch' to find the appropriate branch name."
            fi
            if [ "$(echo $GITBRANCH | cut -d 1)" != "*" ]
            then
               Warning "Branch '$BRANCH' is not the default one"
            fi
            BUILD_CONFIG=$2
            shift;shift;; 
        --gitBranchCur)
            GITBRANCH="$(git branch | grep -e '^\*')"
            if [ "$GITBRANCH" = "" ]
            then
               Error 1 "Branch '$BRANCH' does not exist. Use 'git branch' to find the appropriate branch name."
            fi
            BUILD_CONFIG=$GITBRANCH
            shift;;
        --build-conf-dir)
            CONFIG_PATH="$2"
            if [ ! -d "$CONFIG_PATH" ]
            then
               Error 1 "'$CONFIG_PATH' is not a valid path for option '--build-conf-dir'. Please check."
            fi
            shift;shift;; 
        --box-name)
            APP_NAME="$2"
            shift;shift;; 
        --build-config)
            BUILD_CONFIG=$2
            shift;shift;; 
        --meta)
            META["$(echo $2 | awk -F= '{print $1}')"]="$2"
            echo "Meta set : $2"
            shift;shift;; 
        --meta-data)
            load-meta "$2"
            shift;shift;; 
       --boothook)
            if [ ! -f "$2" ]
            then
               Error 1 "'$2' is not a valid boothook file."
            fi   
            BOOTHOOK="$(pwd)/$2"
            shift;shift;;
        --extra-bs-step)
            BS_STEP="$2"
            BS_STEP_NUM="$(echo "$BS_STEP" | awk -F: '{ print $1}')"
            BS_STEP_FILE="$(echo "$BS_STEP" | awk -F: '{ print $2}')"
            if [ "$BS_STEP_FILE"  = "" ]
            then
               BS_STEP_FILE="$BS_STEP_NUM"
               if [ "$(basename "$BS_STEP_FILE" | grep -e "^[0-9][0-9]*-")" = "" ]
               then
                  BS_STEP_NUM=99
               else
                  BS_STEP_NUM=""
               fi
            fi  
            # Set Full path of step file.
            BS_STEP_FILE="$(dirname "$(pwd)/$BS_STEP_FILE")/$(basename "$BS_STEP_FILE")"
            if [ ! -r "$BS_STEP_FILE" ]
            then
               Warning "Bootstrap file '$BS_STEP_FILE' was not found. Unable to add it to your user_data bootstrap."
            else
               mkdir -p ~/.build/bs_step/$$
               if [ "${BS_STEP_NUM}" = "" ]
               then
                  ln -sf "$BS_STEP_FILE" ~/.build/bs_step/$$/"$(basename "$BS_STEP_FILE").sh"
               else
                  ln -sf "$BS_STEP_FILE" ~/.build/bs_step/$$/${BS_STEP_NUM}-"$(basename "$BS_STEP_FILE").sh"
               fi
               BOOTSTRAP_EXTRA=~/.build/bs_step/$$/
               Info "'$(basename "$BS_STEP_FILE")' added as extra user_data bootstrap step."
            fi  
            shift;shift;; 
        --) 
            shift; break;;
    esac
done

if [ ! -x "$MIME_SCRIPT" ]
then
   Error 1 "'$MIME_SCRIPT' is not executable. Check it."
fi

if [ "$APP_NAME" = "" ]
then
   Error 1 "The required box Name was not defined. Please set --box-name"
fi

if [ "$BUILD_CONFIG" = "" ]
then
   Error 1 "build configuration set not correctly set."
fi
if [ "$GITBRANCH" = "" ]
then
   CONFIG="$CONFIG_PATH/${APP_NAME}.${BUILD_CONFIG}.env"
else
   CONFIG="$CONFIG_PATH/${APP_NAME}.${BUILD_CONFIG}.${GITBRANCH}.env"
fi
if [ ! -r "$CONFIG" ]
then
   Info "Unable to load build configuration file."
   echo "Here are the list of valid configuration from '$CONFIG_PATH':"
   printf "%-10s | %-20s | %-10s\n--------------------------------------------\n" "BoxName" "ConfigName" "BranchName"
   ls -1 $CONFIG_PATH/*.env | sed 's|'"$CONFIG_PATH"'/\(.*\)\.env$|\1|g' | awk -F. '{  
                                                                                     MID=$0;
                                                                                     gsub(sprintf("^%s.",$1), "",MID);
                                                                                     gsub(sprintf(".%s$",$NF),"",MID);
                                                                                     printf "%-10s | %-20s | %-10s\n",$1,MID,$NF
                                                                                    }'
   echo "--------------------------------------------
Set BoxName    with --box-name. Option required.
    ConfigName with --build-config. By default, ConfigName is 'bld'
    BranchName with --gitBranch or --gitBranchCur. By default, BranchName is 'master'"
   Error 1 "No file matching BoxName:${APP_NAME} ConfigName:${BUILD_CONFIG} BranchName:${GITBRANCH}. (${APP_NAME}.${BUILD_CONFIG}.${GITBRANCH}.env) Please check it."
fi

source "$CONFIG"
Info "$CONFIG loaded."

HPC_Check

if [ ! -d "$APP_NAME" ]
then
   Error 1 "You need to be in the directory containing the <BoxName>."
fi

BUILD_DIR=~/.build/$APPPATH
mkdir -p $BUILD_DIR

# Build user_data.
bootstrap_build

