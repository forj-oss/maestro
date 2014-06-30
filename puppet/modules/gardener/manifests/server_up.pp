# == gardener::server_up
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
# Updated do_threaded to false, due to a potential cert issue
# wenlock: think that cacerts is failing to pre-create the certs
#           before we start the instance
#          change pinas to be serialized,
#          saw a thread about puppet race conditions for cert creation
#          do_threaded to false until we move to a higher rev of puppet.
class gardener::server_up (
  $nodes            = ['pinas1'],
  $instance_id      = '',
  $instance_domain  = $domain,
  $do_threaded      = false,
  $blueprint        = 'openstack',
  $server_delay     = 0,
)
{
  # TODO: remove at some point.  This should be used sense we require params to be configured. include gardener::params
  require gardener::params
  include gardener::requirements
  # see pinas.rb server_name
  $udata     = $gardener::params::template_userdata
  $full_host = "<% if server_id == \'\' %><%= server_name %>.${::domain}<%else%><%= server_host %>.${::domain}<%end%>"
  gardener::gen_userdata{'template':
                          domain            => $instance_domain,
                          userdata          => $udata,
                          t_full_q_hostname => $full_host,
                          t_site            => '<%= server_name %>',
                          http_proxy        => '<%= ENV[\'http_proxy\'] %>',
                          template          => $gardener::params::template,
                  }
  debug("using params => ${gardener::params::template}")
  pinas {"server_up ${blueprint}":
    ensure          => present,
    instance_id     => $instance_id,
    domain          => $instance_domain,
    nodes           => $nodes,
    do_parallel     => $do_threaded,
    server_template => $gardener::params::template,
    provider        => $gardener::params::cloud_provider,
    require         => [
                        Class['gardener::requirements'],
                        Class['gardener::params'],
                        Gardener::Gen_userdata['template']
                        ],
    delay           => $server_delay,
  }
}
