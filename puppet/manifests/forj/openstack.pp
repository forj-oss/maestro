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
node /^review.*/ inherits default {

  ::sysadmin_config::setup { 'setup gerrit ports':
      iptables_public_tcp_ports  => [80, 443, 8139, 8140, 29418, 8080],
      sysadmins                  => $sysadmins,
  } ->
  ::sysadmin_config::swap { '512':}
}

#
# we need a utilities server until we fix puppet master bug that prevents server restart, so we can consolidate
node /^util.*/ inherits default {

  #TODO: we need to fix the iptables class because currently the class is only executed once, and it will never overwrite again the rules even if they changed.
  $zuul_ip = read_json('zuul','tool_url',$::json_config_location,true)
  if $zuul_ip != '' and $zuul_ip != '#'
  {
    $statsd_hosts = [$zuul_ip]
    $rules = regsubst ($statsd_hosts, '^(.*)$', '-m udp -p udp -s \1 --dport 8125 -j ACCEPT')
    ::sysadmin_config::setup { 'setup util node ports':
    iptables_public_tcp_ports => [22, 80, 443, 8080, 8081, 8125, 2003],
    iptables_rules4           => $rules,
    sysadmins                 => $sysadmins,
    }
  }
}

#
# this is the jenkins/zuul server
node /^ci.*/ inherits default {

  #$iptables_rules = regsubst ($gearman_workers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')
  #$iptables_rule = regsubst ($zmq_event_receivers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 8888 -s \1 -j ACCEPT')
  ::sysadmin_config::setup { 'setup jenkins, zuul and gearman ports':
    iptables_public_tcp_ports   => [80, 443, 8080, 4730, 29418, 8139, 8140],
    # iptables_rules6           => $iptables_rules,
    # iptables_rules4           => $iptables_rules,
    sysadmins                   => $sysadmins,
  }
}

node /^wiki.*/ inherits default {

#
# all nodes should meet these requirements.
#
  class{'cdk_project::pip':} ->
  class { 'openstack_project::wiki':
    mysql_root_password     => hiera('wiki_db_password'),
    sysadmins               => hiera('sysadmins'),
    ssl_cert_file_contents  => hiera('wiki_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('wiki_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('wiki_ssl_chain_file_contents'),
  }
}
