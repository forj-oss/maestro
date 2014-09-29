#!/bin/bash
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

# This bootscript check is maestro have to instantiate a blueprint at boot.

if [ -f "$INIT_FUNCTIONS" ]
then
   source $INIT_FUNCTIONS
else
   echo "Unable to load 'INIT_FUNCTIONS' ($INIT_FUNCTIONS). Script aborted."
   exit 1
fi

BLUEPRINT="$(GetJson /meta-boot.js blueprint)"

declare -A TEST_BOX_REPOS
Load_test-box_repos

if [ "$BLUEPRINT" != "" ]
then # TODO: Support to receive a different layout then default one.
# restart puppet for install.pp
   service puppetmaster stop
   service apache2 restart || service httpd restart
   service puppet-dashboard-workers restart
# TODO: remove after we're done debuggin:
   find /etc/puppet/hieradata

   if [ "${TEST_BOX_REPOS[$BLUEPRINT]}" = "" ]
   then
      echo "Call of : bp.py --install \"$BLUEPRINT\" -v"
      /opt/config/production/git/maestro/tools/bin/bp.py --install "$BLUEPRINT" -v
   else
      # TODO: Be able to pass all TEST_BOX list to bp.py and wait if needed.
      echo "Test-box: use bp.py with test-box '$BLUEPRINT:${TEST_BOX_REPOS[$BLUEPRINT]}'"
      /opt/config/production/git/maestro/tools/bin/bp.py --install "$BLUEPRINT" -v --test-box "$BLUEPRINT:${TEST_BOX_REPOS[$BLUEPRINT]}"
   fi
   #puppet agent $PUPPET_FLAGS --waitforcert 60 --test 2>&1 | tee -a /tmp/puppet-agent-test4.log
   MODPATH="$(grep modulepath /etc/puppet/puppet.conf | sed 's/\$environment/production/g
                                                             s/^ *modulepath *= *//g')"
   echo "Re-applying: puppet apply /opt/config/production/git/maestro/puppet/manifest/site.pp --modulepath=<from puppet.conf>"
   echo "puppet.conf: modulepath = $MODPATH"

# TODO: remove after we're done debuggin:
   find /etc/puppet/hieradata
# run standalone for MODPATH to update in puppet.conf
   service puppetmaster stop
   service apache2 restart || service httpd restart
   service puppet-dashboard-workers restart
   puppet apply --debug --verbose --modulepath=$MODPATH /opt/config/production/git/maestro/puppet/manifests/site.pp

# restart puppet so all new factors and hiera are loaded. 
   service puppetmaster stop
   service apache2 restart || service httpd restart
   service puppet-dashboard-workers restart
# re run manifest to get the latest changes from new facters
   export FACTERLIB="/var/lib/puppet/lib/facter"
   export PATH="/usr/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"
   puppet agent --debug --verbose $PUPPET_FLAGS --waitforcert 60 --test 2>&1 | tee -a /tmp/puppet-agent-test4.log
fi
