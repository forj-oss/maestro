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
# == 0 when running
# != 0 not runnning
#
# Calling the script from maestro using salt:
# salt 'maestro.*' --out=json cmd.retcode 'sudo -i /usr/lib/forj/toolstatus.sh puppet'

RETVAL=1

puppet() {
  sudo -i service apache2 status > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}

rabbitmq() {
  sudo -i service rabbitmq-server status > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}

uchiwa() {
  sudo -i pm2 list|grep uchiwa.js|grep online > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}

case "$1" in
  puppet)
    puppet
    ;;
  rabbitmq)
    rabbitmq
    ;;
  uchiwa)
    uchiwa
    ;;
  *)
  echo "Usage: {puppet|rabbitmq|uchiwa}"
  ;;
esac
exit $RETVAL