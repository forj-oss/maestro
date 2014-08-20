# == maestro::orchestrator::managedns
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
# Manage dns zone and records for maestro.
#
#
class maestro::orchestrator::managedns (
  $ensure           = present,
  $instance_id      = '42',
  $zone             = 'forj.io',
  $dns_record_data  = hiera_hash('maestro::dns', undef),
  $registered_email = hiera('maestro::dns::global::default_contact','admin@forj.io'),
  $default_zone_ttl = hiera('maestro::dns::global::ttl',600)
)
{
  # 1. Identify the zone_name
  debug("working with instance id => ${instance_id}")
  debug("working with zone        => ${zone}")
  if $instance_id != '' and $instance_id != undef {
    $zone_name = "${instance_id}.${zone}"
  } else {
    $zone_name = $zone
  }
  # 2. default dns_record_data
  if $dns_record_data != undef {
    $dns_data = $dns_record_data
  } else {
    # this is our hard coded default, but we should maintain this in our yaml config.
    # left here to help with testing.
    # ChL: Hardcoded: Kept only maestro, as Maestro will know more from others nodes from hiera later. Maestro is aware only on itself, except hiera said something else.
    $dns_data = parseyaml("
  maestro:
    hostname: 'maestro'
    type: 'A'
    node_search: '/maestro.${instance_id}.*/'
")
#  review:
#    hostname: 'review'
#    type: 'A'
#    node_search: 'review.${instance_id}'
#  ci:
#    hostname: 'ci'
#    type: 'A'
#    node_search: 'ci.${instance_id}'
#  util:
#    hostname: 'util'
#    type: 'A'
#    node_search: 'util.${instance_id}'
#")
  }
  # 3. get nodes to manage
  $nodes = keys($dns_data)
  # 4. Lookup the registered email
  $lookup_email = kit_registration_lookup()
  if $lookup_email == '' or $lookup_email == undef
  {
    $registered_to = $registered_email
  } else
  {
    $registered_to = $lookup_email
  }

  if $ensure == present {
    # 5. Manage the zone
    gardener::dns_zone_manage {$zone_name:
      ensure => present,
      email  => $registered_to,
      ttl    => $default_zone_ttl,
    }
    # 6. Manage the records
    gardener::dns_add_records { $nodes:
      data => $dns_data,
      zone => $zone_name,
    }
  } elsif $ensure == absent {
    # 7. remove the zone sense this is absent
    gardener::dns_zone_manage {$zone_name:
      ensure => absent,
    }
  } else {
    fail("ensure => ${ensure} not supported by maestro::orchestrator::managedns")
  }
}