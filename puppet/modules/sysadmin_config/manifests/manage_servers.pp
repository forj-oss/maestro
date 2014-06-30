# == Class: sysadmin_config:manage_servers
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
#
# Handles server management via hiera.
#

class sysadmin_config::manage_servers (
  $iptables_public_tcp_ports  = hiera_array('sysadmin_config::manage_servers::iptables_public_tcp_ports',undef),
  $iptables_rules4            = hiera_hash('sysadmin_config::manage_servers::iptables_rules4',undef),
  $sysadmins                  = hiera_array('sysadmin_config::manage_servers::sysadmins',undef),
) {

  if $iptables_rules4 != '' and $iptables_rules4 != undef {
    $rule_ip = read_json($iptables_rules4[tool],'tool_url',$::json_config_location,true)
    $statsd_hosts = [$rule_ip]
    #$rules = regsubst ($statsd_hosts, '^(.*)$', '-m udp -p udp -s \1 --dport 8125 -j ACCEPT')
    $rules = regsubst ($statsd_hosts, '^(.*)$', $iptables_rules4[format_rule])
  }
  else
  {
    $rules = []
  }

  class { '::sysadmin_config::servers' :
    iptables_public_tcp_ports => $iptables_public_tcp_ports,
    sysadmins                 => $sysadmins,
    iptables_rules4           => $rules
  }

}
