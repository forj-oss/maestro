#!/bin/bash
## "pupkillinst.sh" script will handle to delete the instances created by
## the kit from eroplus instance, using on choice a puppet manifest.
## xx-util, xx-ci, xx-review (will the instance to clear

function getnst {
     export PUPPET_MODULES=/etc/puppet/modules:/opt/config/production/modules:/opt/config/production/git/maestro/puppet/modules
     puppet apply --debug --verbose --modulepath=$PUPPET_MODULES /opt/config/production/git/maestro/puppet/manifests/maestro-unprovision.pp
} 

getnst
