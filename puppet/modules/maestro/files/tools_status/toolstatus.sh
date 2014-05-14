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
# == 0 when running
# != 0 not runnning
#
# Calling the script from maestro using salt:
# salt 'review.*' --out=json cmd.retcode 'sudo -i /tmp/toolstatus.sh gerrit'
# salt 'ci.*' --out=json cmd.retcode 'sudo -i /tmp/toolstatus.sh jenkins'
# salt 'ci.*' --out=json cmd.retcode 'sudo -i /tmp/toolstatus.sh zuul'
# salt 'util.*' --out=json cmd.retcode 'sudo -i /tmp/toolstatus.sh graphite'
#salt 'ci.*' --out=json cmd.retcode 'sudo -i /tmp/toolstatus.sh pastebin'
#salt 'maestro.*' --out=json cmd.retcode 'sudo -i /tmp/toolstatus.sh puppet'

RETVAL=1

gerrit() {
  sudo -i service gerrit status > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}

jenkins() {
  sudo -i service jenkins status > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}

zuul() {
  sudo -i service zuul status > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}

graphite() {
  sudo -i ps -ef | grep carbon-cache.py | grep -v grep > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}

pastebin() {
  sudo -i service cdkdev-paste status > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}

puppet() {
  sudo -i service apache2 status > /dev/null 2>&1
  RETVAL=$?
  echo $RETVAL
}


case "$1" in
  gerrit)
    gerrit
    ;;
  jenkins)
    jenkins
    ;;
  zuul)
    zuul
    ;;
  graphite)
    graphite
    ;;
  pastebin)
    pastebin
    ;;
  puppet)
    puppet
   ;;
  *)
  echo "Usage: {gerrit|jenkins|zuul|graphite|pastebin|puppet}"  
  ;;
esac
exit $RETVAL