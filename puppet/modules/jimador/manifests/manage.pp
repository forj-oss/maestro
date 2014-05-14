# == Class: jimador::manage
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
# Handle bulk configuration data from hiera
# main goal is to manage data that comes from hiera, and transfer this to config.json
# based on module install current state.
#

class jimador::manage (
  $jimador_discover      = hiera_hash('jimador::discover',undef),      # writes data for site->node->tools
  $jimador_site          = hiera_hash('jimador::site',undef),         # writes key, value properties for site section
  $jimador_documentation = hiera_array('jimador::documentation',undef),# write documentation hash for site section
  $jimador_tools_filter  = hiera_array('jimador::default_tools_filter',['zuul']),
) {

  if $jimador_discover {
    $tool_keys = keys($jimador_discover)
    jimador::discover { $::fqdn:
      tools        => $tool_keys,
      tools_filter => $jimador_tools_filter,
      tools_data   => $jimador_discover,
    }
  }

  if $jimador_documentation {
    jimador::write_config_yaml { 'documentation':
      data    => $jimador_documentation,
      require => Jimador::Discover[$::fqdn],
    }
  }

  if $jimador_site {
    $site_keys = keys($jimador_site)
    jimador::write_sitekeys { $site_keys:
      data    => $jimador_site,
      require => Jimador::Discover[$::fqdn],
    }
  }

}
