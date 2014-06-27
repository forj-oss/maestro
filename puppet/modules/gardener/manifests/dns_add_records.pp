# == gardener::dns_add_records
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
# add multiple dns records.   We assume the zone and record data is provided.
# we will also lookup the compute information based on regular expression or not.
# data will contain the information needed to action the record, title/action_node
# will contain the record to make present.
#
# data should be in the form of:
# {
#      'node1' : {
#                  'hostname'    : 'node1',
#                  'domain'      : 'forj.io',
#                  'type'        : 'A',
#                  'node_search' : '/node.*/',   # this searches for the first occurence of node for the compute name.
#                 },
#       'node2' : {
#                  'hostname'    : 'node2',
#                  'domain'      : 'forj.io',
#                  'type'        : 'A',
#                  'node_search' : 'node2',   # this searches for an exact match, this can also be the compute id
#                 },
# }
# This can be created parsed into an object with yaml or json using parseyaml or parsejson
define gardener::dns_add_records (
  $action_node    = $title,
  $data           = undef,
  $zone           = undef,
) {
    include gardener::requirements
    if $data == undef {
      warning('must provide hash of data objects with properties for nodes of hostname, type, node_search')
    }

    # 1. lookup the compute id for the node
    $compute_name_lookup = compute_id_lookup($data[$action_node]['node_search'])
    if has_key($data[$action_node], 'domain') {
      $zone_name = $data[$action_node]['domain']
    } else {
      $zone_name = $zone
    }
    # 2. create record
    if  $zone_name == undef or $zone_name == '' or
        $data[$action_node]['type'] == '' or $data[$action_node]['type'] == undef or
        $compute_name_lookup == '' or $compute_name_lookup == undef
    {
      warning('skipping gardener::dns_add_records due to un-met input requirements.')
    } else {
      gardener::dns_record_manage {$data[$action_node]['hostname']:
        ensure       => present,
        zone         => $zone_name,
        record_type  => $data[$action_node]['type'],
        compute_name => $compute_name_lookup,
        require      => Class['gardener::requirements'],
      }
    }
}
