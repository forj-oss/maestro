#!/bin/bash

#
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
#quick fix: defect #102
LOG_FILE=/var/log/pup-master-fix.log
> $LOG_FILE 2<&1
service puppetmaster stop >> $LOG_FILE 2<&1
service salt-master stop >> $LOG_FILE 2<&1
service puppet stop >> $LOG_FILE 2<&1
service puppet-dashboard-workers stop >> $LOG_FILE 2<&1
service puppetmaster start >> $LOG_FILE 2<&1
service salt-master start >> $LOG_FILE 2<&1
service puppet start >> $LOG_FILE 2<&1
service puppet-dashboard-workers start >> $LOG_FILE 2<&1
