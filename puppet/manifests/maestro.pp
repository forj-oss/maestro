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
# This manifest file is currently working in vagrant orchestrator box.
# we will port this later to work on a deployed system.
#
#
# Setup host so that we can deal with vagrant configs and ip based configs
# this section still requires some work

$sysadmins = []

# implements hiera_data installations
node default {
    # global's
  Exec { path => [
    '/bin/',
    '/sbin/',
    '/usr/bin/',
    '/usr/sbin/',
    '/usr/local/bin/'
    ]
  }
  hiera_include('classes')
}

#
# This manifest file is currently working in vagrant orchestrator box.
# we will port this later to work on a deployed system.

node /^maestro.*/ inherits default {

  # moved up sysadmin config due to integration of dashboard and maestro components
  # main app for this server, the controller ui for cdk
  notify{ 'maestro ui box execution': } ->
  ::sysadmin_config::setup { 'setup puppetmaster and dashboard ports':
      iptables_public_tcp_ports => [4505, 4506, 8139, 8140, 80, 443, 3000, 8080],
      sysadmins                 => $sysadmins,
  } ->
  ::sysadmin_config::swap { '512':}
}
