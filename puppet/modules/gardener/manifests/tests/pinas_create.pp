# == gardener::tests::pinas_create
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
# testing the create process with pinas

class gardener::tests::pinas_create (
  $image_name = 'Ubuntu Precise 12.04 LTS Server 64-bit 20121026 (b)',
  $nodes = ['pinasnode1','pinasnode2','pinasnode3'],
) {
  include gardener::requirements



  $userdata = '/tmp/mime.txt'
#  $metadata = "erosite=${::hostname},erodomain=${::domain}"
  $ec2_tmp1  = '<% if defined?(@helion_public_ipv4) %><%= @helion_public_ipv4 %>'
  $ipa_tmp2  = '<% elsif defined?(@ipaddress)%><%= @ipaddress %>'
  $fqdn_tmp3 = '<% else %><%= @fqdn %><% end %>'
  $getiptemplate = "${ec2_tmp1}${ipa_tmp2}${fqdn_tmp3}"
  $eroip = inline_template($getiptemplate)

  $m1  = "erosite=${::hostname},"
  $m2  = "erodomain=${::domain},"
  $m3  = "eroip=${eroip},"
  $m4  = "cdkdomain=${::domain},"
  $m5  = 'cdksite=<%= server_name %>'
  $metadata = "${m1}${m2}${m3}${m4}${m5}"

  $template = {
      image_name      => $image_name, # can also be a number like 48335
      flavor_name     => 'standard.xsmall', # can also be a number like 100
      key_name        => 'nova',
      security_groups => ['default'],
      user_data       => $userdata,
      meta_data       => $metadata,
  }
  # see pinas.rb server_name
  $full_host = "<%= server_name %>.${::domain}"
  gardener::gen_userdata{'template':
                          domain            => $::domain,
                          userdata          => $userdata,
                          t_full_q_hostname => $full_host,
                          t_site            => '<%= server_name %>',
                  } ->
  pinas {'test create old openstack':
    ensure          => present,
    instance_id     => '42',
    domain          => $::domain,
    nodes           => $nodes,
#    nodes           => ['pinasnode1'],
    do_parallel     => false,
    server_template => $template,
    provider        => hp,
    require         => Class['gardener::pinas_requirements'],
    delay           => 0,
  }
}
