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

if [ "$BLUEPRINT" != "" ]
then # TODO: Support to receive a different layout then default one.
   /opt/config/production/git/maestro/tools/bin/bp.py --install "$BLUEPRINT" -v
   puppet agent $PUPPET_FLAGS --waitforcert 60 --test 2>&1 | tee -a /tmp/puppet-agent-test4.log
fi



