#######################################################
#
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
# Puppet Client
# let's get some graphite reports.
class puppet::reports::graphite (
  $status          = hiera('puppet::reports::graphite::status', enabled),
  $graphite_server = hiera('puppet::reports::graphite::graphite_server', undef),
  $graphite_port   = hiera('puppet::reports::graphite::graphite_port',2003),
  ) {
  if $graphite_server == undef
  {
    $graphite_host = read_json('graphite','tool_url',$::json_config_location,true)
  }
  else
  {
    $graphite_host = $graphite_server
  }
  if $graphite_host != undef and $graphite_host != '' and $status == enabled
  {
    file { '/etc/puppet/graphite.yaml':
      ensure  => file,
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '0444',
      content => template('puppet/graphite.yaml.erb'),
    }
  }

} # end class puppet
