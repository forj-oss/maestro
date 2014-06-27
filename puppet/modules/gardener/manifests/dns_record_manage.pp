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
define gardener::dns_record_manage (
  $node_name    = $title,
  $zone         = '',
  $compute_name = '',
  $record_type  = 'A',
  $ensure       = present,
)
{
  include gardener::requirements
  if (regsubst($zone,'(.*)(.$)','\2') == '.') # check if the zone already has a period at the end.
  {
    $zone_name = $zone
  } else
  {
    $zone_name = "${zone}."
  }
  if(is_domain_managed($zone_name) == true)
  {
    $ip_address = compute_public_ip_lookup($compute_name)
    # check that we have an ip so we can gracefully skip with a warning and not fail
    if ($ip_address != '' and $ensure == present) or $ensure == absent
    {
      pinasdns {"${node_name}.${zone_name}":
        ensure          => $ensure,
        record_type     => $record_type,
        ip_data         => $ip_address,
        provider        => record,
        require         => Class['gardener::requirements'],
      }
    } else
    {
      warning("Unable to set dns record for ${compute_name}, no public ip found or none currently assigned.")
    }
  }
}
