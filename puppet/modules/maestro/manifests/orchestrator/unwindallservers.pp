# == Class: ::maestro::orchestrator::unwindallservers
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
# remove all servers for this maestro instance
#
class maestro::orchestrator::unwindallservers(
  $nodes       = hiera('maestro::nodes', ['review']),
  $instance    = hiera('maestro::instance_id', $::maestro_id),
  $zone_name   = hiera('maestro::orchestrator::zone',$::erodomain),
)
{
  if $instance == '' or $instance == undef
  {
    fail('Argument error: can not provide empty instance name')
  }
  include gardener::params
  class {'maestro::orchestrator::managedns':
    ensure           => absent,
    instance_id      => $instance,
    zone             => $zone_name,
  } ->
  class { 'gardener::server_destroy':
    nodes            => $nodes,
    instance_id      => $instance,
  }

  notify { 'completed unwindallservers':
        message => join(["************ removed ${instance}  **********
                  domain = ${maestro::instance_domain}
                  environment = ${::environment}
              *************************************************" ]),
          }
}
