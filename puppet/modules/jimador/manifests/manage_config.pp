# == Class: jimador::manage_config
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
# TODO: we should fail if UDEF is passed..
define jimador::manage_config (
  $tool          = $title,
  $tools_hash    = UNDEF,
  $node_name     = UNDEF,
  $default_tools = [],
  $filter_tools  = [], # list of tools that will not be included in init of empty config.json
)
{
  notice("managing config.json for ${tool}")
  debug('data')
  debug($tools_hash)
  debug('default_tools')
  debug($default_tools)
  $tool_url    = $tools_hash[$tool]['tool_url']
  $tool_config = $tools_hash[$tool]['tool_config']
  $tool_email  = $tools_hash[$tool]['tool_email']
  $category    = $tools_hash[$tool]['category']
  $dname       = $tools_hash[$tool]['dname']
  $desc        = $tools_hash[$tool]['desc']
  $icon        = $tools_hash[$tool]['icon']
  $visible     = $tools_hash[$tool]['visible']
  # Static values to be toggled when discovering an app
  $status      = 'online'
  $statistics  = false

  if ($node_name != UNDEF and $node_name != '')
  {
    if ($tool_email != UNDEF and $tool_email != '')
    {
      $email_opt     = ',email'
      $email_opt_val = "%;${tool_email}"
    }
    else
    {
      $email_opt     = ''
      $email_opt_val = ''
    }

    if $tool_url != '' {
      save_tools( $node_name,
                  $tool,
                  "name,tool_url,settings_url${email_opt},status,category,dname,desc,icon,visible,statistics",
                  "${tool}%;${tool_url}%;${tool_config}${email_opt_val}%;${status}%;${category}%;${dname}%;${desc}%;${icon}%;${visible}%;${statistics}",
                  $default_tools,
                  $filter_tools
                )
      notify{"${tool} url was found ${node_name}, url is ${tool_url}":}
      if ($::maestro_id != UNDEF and $::maestro_id != '')
      {
        save_siteinfo( 'id', $::maestro_id)
      }
      if ($::maestro_blueprint != UNDEF and $::maestro_blueprint != '')
      {
        save_siteinfo( 'blueprint', $::maestro_blueprint)
      }
      # can be turned on with export FACTER_maestro_projects=true
      #if ($::maestro_projects != UNDEF and $::maestro_projects != '')
      #{
      #  save_siteinfo( 'projects', $::maestro_projects)
      #} else
      #{
      #  save_siteinfo( 'projects', false)
      #}
      #TODO: This is hardcoded for 1.0
      save_siteinfo( 'projects', true)
      # can be turned on with export FACTER_maestro_users=true
      if ($::maestro_users != UNDEF and $::maestro_users != '')
      {
        save_siteinfo( 'users', $::maestro_users)
      } else
      {
        save_siteinfo( 'users', false)
      }
    }
    else
    {
      notify{"${tool} url was not found on node ${node_name}":}
    }

  }
}
