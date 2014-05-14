# == gardener::dns_record_manage
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
# Manage dns records using dnspinas
#
#
define gardener::dns_zone_manage (
  $zone          = $title,
  $ensure       = present,
  $email         = '',
  $ttl           = 600,
)
{
  if (regsubst($zone,'(.*)(.$)','\2') == '.') # check if the zone already has a period at the end.
  {
    $zone_name = $zone
  } else
  {
    $zone_name = "${zone}."
  }
  include gardener::requirements
  pinasdns {$zone_name:
    ensure          => $ensure,
    email           => $email,
    ttl             => $ttl,
    provider        => zone,
    require         => [
                        Class['gardener::requirements'],
                        Class['gardener::params'],
                        ],
  }
}