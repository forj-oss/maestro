
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
# cleanup

mv /var/log/cloud-init.log /var/log/cloud-init.proto.$RANDOM.log
[ -d /var/lib/puppet/ssl ] && rm -fr /var/lib/puppet/ssl
[ -f /meta.js ] && rm -f /meta.js
[ -f /meta-boot.js ] && rm -f /meta-boot.js
TMP_HOST=/tmp/hosts.$$.$RANDOM
cat /etc/hosts|grep -v maestro > $TMP_HOST
mv $TMP_HOST /etc/hosts
umount /config
[ -d /config ] && rm -fr /config
[ -f /get-pip.py ] && rm -f /get-pip.py
exit 0
