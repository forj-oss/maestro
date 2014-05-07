#!/bin/bash
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
## "pupkillinst.sh" script will handle to delete the instances created by
## the kit from eroplus instance, using on choice a puppet manifest.
## xx-util, xx-ci, xx-review (will the instance to clear

function getnst {
     export PUPPET_MODULES=/etc/puppet/modules:/opt/config/production/modules:/opt/config/production/git/maestro/puppet/modules
     puppet apply --debug --verbose --modulepath=$PUPPET_MODULES /opt/config/production/git/maestro/puppet/manifests/maestro-unprovision.pp
} 

getnst
