#!/bin/bash
# Copyright 2013 OpenStack Foundation.
# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

function test-box
{
  echo "test-box: not implemented."
}

if [ -f "$INIT_FUNCTIONS" ]
then
   echo "FORJ '$INIT_FUNCTIONS' loaded."
   source $INIT_FUNCTIONS
   declare -A TEST_BOX_REPOS
   Load_test-box_repos
fi

SCRIPT_NAME=$(basename $0)
# SCRIPT_DIR=$(readlink -f "$(dirname $0)")
SCRIPT_DIR="${1}"
MODULE_PATH=/etc/puppet/modules

function remove_module {
  local SHORT_MODULE_NAME=$1
  if [ -n "$SHORT_MODULE_NAME" ]; then
    rm -Rf "$MODULE_PATH/$SHORT_MODULE_NAME"
  else
    echo "ERROR: remove_module requires a SHORT_MODULE_NAME."
  fi
}

# Array of modules to be installed key:value is module:version.
declare -A MODULES
declare -a ORDERS

# Array of modues to be installed from source and without dependency resolution.
# key:value is source location, revision to checkout
declare -A SOURCE_MODULES
declare -a SOURCE_ORDERS

#NOTE: if we previously installed kickstandproject-ntp we nuke it here
# since puppetlabs-ntp and kickstandproject-ntp install to the same dir
if grep kickstandproject-ntp /etc/puppet/modules/ntp/Modulefile &> /dev/null; then
  remove_module "ntp"
fi

remove_module "gearman" #remove old saz-gearman
remove_module "limits" # remove saz-limits (required by saz-gearman)

# load additional modules from modules.env
# modules.env should exist in the same folder as install_modules.sh
# * use export MODULE_FILE to specify an alternate config
#   file that can be used to pull environment specific modules.
#   the default is empty.
# * allow modules.env to unset DEFAULT_MODULES to something other than 1
#   this should disable default modules from installing.

export DEFAULT_MODULES=1

#if has parameter and the file exists value use it, instead of default
if [ -n "$1" ] && [ -f "$1" ]; then
  . ${1}
  echo "Loaded ${1}"
else
  MODULE_FILE=${MODULE_FILE:-modules.env}
  if [ -f "${SCRIPT_DIR}/${MODULE_FILE}" ] ; then
    . "${SCRIPT_DIR}/${MODULE_FILE}"
    echo "Loaded ${SCRIPT_DIR}/${MODULE_FILE}"
  fi
fi

if [ "${DEFAULT_MODULES}" = "1" ] ; then
  echo "... using default modules ..."
  MODULES["puppetlabs-ntp"]="0.2.0"; ORDERS+=( "puppetlabs-ntp" )

# freenode #puppet 2012-09-25:
# 18:25 < jeblair> i would like to use some code that someone wrote,
# but it's important that i understand how the author wants me to use
# it...
# 18:25 < jeblair> in the case of the vcsrepo module, there is
# ambiguity, and so we are trying to determine what the author(s)
# intent is
# 18:30 < jamesturnbull> jeblair: since we - being PL - are the author
# - our intent was not to limit it's use and it should be Apache
# licensed
  MODULES["openstackci-vcsrepo"]="0.0.8"; ORDERS+=( "openstackci-vcsrepo" )

  MODULES["puppetlabs-apache"]="0.0.4"; ORDERS+=( "puppetlabs-apache" )
  MODULES["puppetlabs-passenger"]="0.3.0"; ORDERS+=( "puppetlabs-passenger" )
  MODULES["puppetlabs-apt"]="1.4.2"; ORDERS+=( "puppetlabs-apt" )
  MODULES["puppetlabs-haproxy"]="0.4.1"; ORDERS+=( "puppetlabs-haproxy" )
  MODULES["puppetlabs-mysql"]="0.6.1"; ORDERS+=( "puppetlabs-mysql" )
  MODULES["puppetlabs-postgresql"]="3.4.1"; ORDERS+=( "puppetlabs-postgresql" )
  MODULES["puppetlabs-stdlib"]="4.3.2"; ORDERS+=( "puppetlabs-stdlib" )
  MODULES["saz-memcached"]="2.0.2"; ORDERS+=( "saz-memcached" )
  MODULES["spiette-selinux"]="0.5.1"; ORDERS+=( "spiette-selinux" )
  MODULES["rafaelfc-pear"]="1.0.3"; ORDERS+=( "rafaelfc-pear" )
  MODULES["puppetlabs-inifile"]="1.0.0"; ORDERS+=( "puppetlabs-inifile" )
  MODULES["puppetlabs-firewall"]="0.0.4"; ORDERS+=( "puppetlabs-firewall" )
  MODULES["puppetlabs-puppetdb"]="3.0.1"; ORDERS+=( "puppetlabs-puppetdb" )
  MODULES["stankevich-python"]="1.6.6"; ORDERS+=( "stankevich-python" )
  MODULES["garethr-erlang"]="0.3.0"; ORDERS+=( "garethr-erlang" )
  MODULES["sensu-sensu"]="1.2.1"; ORDERS+=( "sensu-sensu" )
  MODULES["camptocamp-openldap"]="0.5.3"; ORDERS+=( "camptocamp-openldap" )
  MODULES["stahnma-epel"]="1.0.0"; ORDERS+=( "stahnma-epel" )
  MODULES["nanliu-staging"]="0.3.1"; ORDERS+=( "nanliu-staging" )
  # MODULES["puppetlabs-rabbitmq"]="4.0.0"; ORDERS+=( "puppetlabs-rabbitmq" )

# Source modules should use tags, explicit refs or remote branches because
# we do not update local branches in this script.
  SOURCE_MODULES["https://github.com/miqui/puppetlabs-rabbitmq"]="origin/master"; SOURCE_ORDERS+=( "https://github.com/miqui/puppetlabs-rabbitmq" )
  SOURCE_MODULES["https://github.com/nibalizer/puppet-module-puppetboard"]="2.4.0"; SOURCE_ORDERS+=( "https://github.com/nibalizer/puppet-module-puppetboard" )
  SOURCE_MODULES["https://git.openstack.org/openstack-infra/puppet-storyboard"]="origin/master"; SOURCE_ORDERS+=( "https://git.openstack.org/openstack-infra/puppet-storyboard" )
fi

if [ -z "${!MODULES[*]}" ] && [ -z "${!SOURCE_MODULES[*]}" ] ; then
  echo "nothing to do , unable to find MODULES env or SOURCE_MODULES"
  exit 0
fi

MODULE_LIST=`puppet module list`

# Transition away from old things
if [ -d /etc/puppet/modules/vcsrepo/.git ]
then
  rm -rf /etc/puppet/modules/vcsrepo
fi

# Install all the modules
for MOD in ${!ORDERS[@]} ; do
  echo -n "Installing module ${ORDERS[$MOD]}... "
  # If the module at the current version does not exist upgrade or install it.
  if ! echo ${MODULE_LIST} | grep "${ORDERS[$MOD]} ([^v]*v${MODULES[${ORDERS[$MOD]}]}" >/dev/null 2>&1
  then
    echo "v${MODULES[${ORDERS[$MOD]}]}"
    # Attempt module upgrade. If that fails try installing the module.
    if ! puppet module upgrade ${ORDERS[$MOD]} --version ${MODULES[${ORDERS[$MOD]}]} >/dev/null 2>&1
    then
      # This will get run in cron, so silence non-error output
      puppet module install ${ORDERS[$MOD]} --version ${MODULES[${ORDERS[$MOD]}]} >/dev/null
    fi
  else
    echo "already exists."
  fi
done

MODULE_LIST=`puppet module list`

# Make a second pass, just installing modules from source
for MOD in ${!SOURCE_ORDERS[@]} ; do
  # get the name of the module directory
  if [ `echo ${SOURCE_ORDERS[$MOD]} | awk -F. '{print $NF}'` = 'git' ]; then
    echo "Remote repos of the form repo.git are not supported: ${SOURCE_ORDERS[$MOD]}"
    exit 1
  fi
  MODULE_NAME=`echo ${SOURCE_ORDERS[$MOD]} | awk -F- '{print $NF}'`
  echo "Installing module ${MODULE_NAME} (from git source)..."
  # set up git base command to use the correct path
  GIT_CMD_BASE="git --git-dir=${MODULE_PATH}/${MODULE_NAME}/.git --work-tree ${MODULE_PATH}/${MODULE_NAME}"
  # treat any occurrence of the module as a match
  if ! echo ${MODULE_LIST} | grep "${MODULE_NAME}" >/dev/null 2>&1; then
    # clone modules that are not installed
    git clone ${SOURCE_ORDERS[$MOD]} "${MODULE_PATH}/${MODULE_NAME}"
  else
    if [ ! -d ${MODULE_PATH}/${MODULE_NAME}/.git ]; then
      echo "Found directory ${MODULE_PATH}/${MODULE_NAME} that is not a git repo, deleting it and reinstalling from source"
      remove_module ${MODULE_NAME}
      git clone ${SOURCE_ORDERS[$MOD]} "${MODULE_PATH}/${MODULE_NAME}"
    elif [ `${GIT_CMD_BASE} remote show origin | grep 'Fetch URL' | awk -F'URL: ' '{print $2}'` != ${SOURCE_ORDERS[$MOD]} ]; then
      echo "Found remote in ${MODULE_PATH}/${MODULE_NAME} that does not match desired remote ${SOURCE_ORDERS[$MOD]}, deleting dir and re-cloning"
      remove_module ${MODULE_NAME}
      git clone ${SOURCE_ORDERS[$MOD]} "${MODULE_PATH}/${MODULE_NAME}"
    fi
  fi

  # fetch the latest refs from the repo
  ${GIT_CMD_BASE} remote update

  test-box "${MODULE_PATH}" "${MODULE_NAME}" "$(echo "${SOURCE_ORDERS[$MOD]}"| awk -F/ '{print $NF}')"

  if [ $? -eq 0 ]
  then
    # make sure the correct revision is installed, I have to use rev-list b/c rev-parse does not work with tags
    if [ `${GIT_CMD_BASE} rev-list HEAD --max-count=1` != `${GIT_CMD_BASE} rev-list ${SOURCE_MODULES[${SOURCE_ORDERS[$MOD]}]} --max-count=1` ]; then
      # checkout correct revision
      ${GIT_CMD_BASE} checkout ${SOURCE_MODULES[${SOURCE_ORDERS[$MOD]}]}
    fi
  fi

done
