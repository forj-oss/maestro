
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
# Configure Openstack config from a freezed version maintained by FORJ team.
set -x
#echo "host jenkins.cdkdev.org
#     StrictHostKeyChecking=no" >> ~/.ssh/config

export HOME=/root
# Uses local stable resource instead of internet one. See ubuntu@jenkins.cdkdev.org

cd /opt/config/production/git
CloneRepo config https://review.forj.io/p/oo-infra/config $GITBRANCH
cd config
git config core.autocrlf false
set +x
