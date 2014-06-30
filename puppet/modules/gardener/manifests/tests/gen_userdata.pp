# == gardener::tests::dns_zone_manage_prsent
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
# A standalone test for gen_userdata that produces ~/mime.txt file
# Normally this function is used to generate the mime bootstrap for all nodes.
#
class gardener::tests::gen_userdata (
  $instance_id     = '42',
  $instance_domain = 'cdkdev.org',
  $image_name      = 'proto2b',
  $fspec_userdata  = '~/mime.txt',
)
{
  include gardener::requirements
  class {'gardener::params':
      image_name         => $image_name,
      # can also be a number like 100
      flavor_name        => 'standard.xsmall',
      key_name           => 'nova',
      network_name       => 'private',
      template_userdata  => $fspec_userdata,
  }
  $udata     = $gardener::params::template_userdata
  $full_host = "<% if server_id == \'\' %><%= server_name %>.${::domain}<%else%><%= server_host %>.${::domain}<%end%>"
  gardener::gen_userdata{'template':
                          domain            => $instance_domain,
                          userdata          => $udata,
                          t_full_q_hostname => $full_host,
                          t_site            => '<%= server_name %>',
                          http_proxy        => '<%= ENV[\'http_proxy\'] %>',
                          template          => $gardener::params::template,
                          require           => [  Class['gardener::requirements'],
                                                  Class['gardener::params'] ],
                  }
}
