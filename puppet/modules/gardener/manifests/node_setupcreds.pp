# == gardener::node_setupcreds
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
# Attempt to setup FOG_RC creds on a node using puppetmaster data
#

class gardener::node_setupcreds(
  $cloudcreds_path  = hiera('gardener::cloudcreds_path', '/opt/config/fog/cloud.fog'),
  $local_fog_path = hiera('gardener::default::fog_path', '/opt/config/fog'),
  $local_fog_file = hiera('gardener::default::fog_file', 'cloud.fog'),
) {

  tag 'gardener::node_setupcreds'
  $cloudcreds_content = file_master($cloudcreds_path)

  if ($cloudcreds_content != undef and $cloudcreds_content != '')
  {
    if $local_fog_path == '/opt/config/fog'
    {
      if ! defined(File['/opt']) {
        file { '/opt' :
          ensure => directory,
          mode   => '0755',
        }
      }
      if ! defined(File['/opt/config']) {
        file { '/opt/config' :
          ensure  => directory,
          mode    => '0755',
          before  => File[$local_fog_path],
          require => File['/opt'],
        }
      }
    }
    if ! defined(File[$local_fog_path]) {
      file { $local_fog_path :
        ensure => directory,
        mode   => '0700',
      }
    }
    $local_cloudcreds = joinpath($local_fog_path, $local_fog_file)
    file { $local_cloudcreds:
      ensure  => present,
      content => $cloudcreds_content,
      replace => true,
      require => File[$local_fog_path],
      mode    => '0700',
    }
  } else {
    warning('skipping setup for fog creds on node.')
  }
}
