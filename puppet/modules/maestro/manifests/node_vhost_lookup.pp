# == maestro::node_vhost_lookup
# Contains the parameteres for the vhost or ip address to be used for our nodes or apps.
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
class maestro::node_vhost_lookup(
  $alias_name  = hiera('maestro::node_vhost_lookup::alias_name', $::fqdn)
) {
  include gardener::requirements
  if $::maestro_id != undef and $::maestro_id != ''
  {
    $compute_public_ip = compute_public_ip_lookup("${::hostname}.${::maestro_id}")
  } else
  {
    $compute_public_ip = compute_public_ip_lookup($::hostname)
  }

  if str2bool($::vagrant_guest) == true {  # use a vagrant localhost when doing local testing
    $vname = 'localhost'
  } elsif($alias_name != '' and domain_record_exists($alias_name, 'A' )) { # use dns when it's available via cloud api's.
    $vname = $alias_name
  } elsif ($compute_public_ip != '' and $compute_public_ip != undef) { # use the cloud public ip when it's available.
    $vname = $compute_public_ip
  } elsif ( $::helion_public_ipv4 != '') { # fall back to trying an external service from hpcloud
    $vname = $::helion_public_ipv4
  } elsif ( $::ec2_public_ipv4 != '') { # fall back to trying an external service from ec2
    $vname = $::ec2_public_ipv4
  } else {
    fail('no public routable ip could be determined.  stop this puppet run')
# TODO delete after we determine this is good:    $vname = inline_template('<% if defined?(@ec2_public_ipv4) %><%= @ec2_public_ipv4 %><% elsif defined?(@ipaddress_eth0)%><%= @ipaddress_eth0 %><% else %><%= @fqdn %><% end %>')
  }
}
