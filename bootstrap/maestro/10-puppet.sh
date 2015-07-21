#!/bin/bash -x
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

# This bootscript configure Maestro Box to become puppet Orchestrator.

if [ -f "$INIT_FUNCTIONS" ]
then
   source $INIT_FUNCTIONS
else
   echo "Unable to load 'INIT_FUNCTIONS' ($INIT_FUNCTIONS). Script aborted."
   exit 1
fi

PUPPET_DEBUG="$(GetJson /meta-boot.js PUPPET_DEBUG)"
GITBRANCH="$(GetJson /meta-boot.js gitbranch)"

if [ "$PUPPET_DEBUG" = "True" ]
then
  PUPPET_FLAGS="--debug --verbose"
fi

#
# we use install_puppet.sh and install_modules.sh for puppet setup support
# TODO: consider if we source/download this file from openstack public repos
#
# MODULE_FILE will be changed to non-default when GITBRANCH is empty or not
# master.
if [ ! "${GITBRANCH}" = "" ] && [ ! "${GITBRANCH}" = "master" ] ; then
  export MODULE_FILE=modules.$GITBRANCH.env
fi
bash /opt/config/production/git/maestro/puppet/install_puppet.sh
# Regarding issues with the latest passenger release and its dependencies
# we need to set for an older installation version.
puppet module install puppetlabs-apache --version 0.4.0
puppet module install puppetlabs-passenger --version 0.3.0
bash /opt/config/production/git/maestro/puppet/install_modules.sh "/opt/config/production/git/maestro/puppet/modules.env"
bash /opt/config/production/git/maestro/hiera/hiera.sh


find /opt/config/production -type d -exec chmod 755 {} \;
find /opt/config/production \( -path \*/tools/bin -o -path \*/bootstrap -o -path \*/build -o -path \*/.git \) -prune -o -type f -exec chmod 644 {} \;
find /opt/config/production -exec chown puppet:puppet {} \;
find /opt/config/fog -exec chown puppet:puppet {} \;

if [ "$http_proxy" != "" ] && [ -r /etc/default/puppet ] && [ "$(grep http_proxy /etc/default/puppet)" = "" ]
then
   grep http_proxy /etc/environment >> /etc/default/puppet
fi


function run1
{
export environment=production
export PUPPET_MODULES=/opt/config/$environment/puppet/modules
export PUPPET_MODULES=$PUPPET_MODULES:/opt/config/$environment/git/maestro/puppet/modules
export PUPPET_MODULES=$PUPPET_MODULES:/opt/config/$environment/git/config/modules
export PUPPET_MODULES=$PUPPET_MODULES:/etc/puppet/modules

_FQDN=$(facter fqdn)
puppet cert generate $_FQDN
puppet apply $PUPPET_FLAGS --modulepath=$PUPPET_MODULES /opt/config/production/puppet/manifests/bootstrap_hiera.pp 2>&1 | tee -a /tmp/puppet-applybootstrap1.log
puppet apply $PUPPET_FLAGS --modulepath=$PUPPET_MODULES /opt/config/production/puppet/manifests/bootstrap_hiera.pp 2>&1 | tee -a /tmp/puppet-applybootstrap2.log
puppet apply $PUPPET_FLAGS --modulepath=$PUPPET_MODULES /opt/config/production/puppet/manifests/site.pp 2>&1 | tee -a /tmp/puppet-applysite1.log
service puppetmaster stop
service apache2 restart || service httpd restart
puppet apply $PUPPET_FLAGS --modulepath=$PUPPET_MODULES /opt/config/production/puppet/manifests/site.pp 2>&1 | tee -a /tmp/puppet-applysite2.log
service puppetmaster stop
service apache2 restart || service httpd restart
# Added due to npm install sometimes throwing undefined install errors... clears up after subsequent runs.
# TODO: find how we can delay maestro ui install till after base orchestration is running.... consideration for future release.
puppet apply $PUPPET_FLAGS --modulepath=$PUPPET_MODULES /opt/config/production/puppet/manifests/site.pp 2>&1 | tee -a /tmp/puppet-applysite3.log
# we run puppet with passenger, this service should not start
service puppetmaster stop
service apache2 restart || service httpd restart
service puppet-dashboard-workers restart
}
run1

puppet agent $PUPPET_FLAGS --waitforcert 60 --test 2>&1 | tee -a /tmp/puppet-agent-test3.log
