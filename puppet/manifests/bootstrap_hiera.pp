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
#
# Bootstrap the server to become a puppetmaster

node /.*(maestro|precise32).*/ {
  #
  # all nodes should meet these requirements.
  #
  # global's
  Exec { path => [
    '/bin/',
    '/sbin/',
    '/usr/bin/',
    '/usr/sbin/',
    '/usr/local/bin/'
    ]
  }

  include gardener
  require cdk_project::pip
  notice("openstack puppetmaster blueprint working for ${::fqdn}")

  class { 'hiera':
    data_class => 'runtime_project::hiera_setup',
  } ->
  # puppetmaster : 4505, 4506
  # salt         : 8139, 8140
  # dashboard    : 80, 443, 3000
  ::sysadmin_config::setup { 'setup puppetmaster and dashboard ports':
    iptables_public_tcp_ports => [4505, 4506, 8139, 8140, 80, 443, 3000, 8080],
    sysadmins                 => $sysadmins,
  }
}


