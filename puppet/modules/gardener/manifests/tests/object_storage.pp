# == gardener::tests::object_storage
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

# TODO: ChL: This file has currently not been updated related
#   to credentials. But normally, any fog task uses /root/.fog.
#   credentials should not exist in puppet files anymore.

class gardener::tests::object_storage (
  $provider      = hiera('gardener::tests::object_storage::provider'),
  $hp_access_key = hiera('gardener::tests::object_storage::hp_access_key'),
  $hp_secret_key = hiera('gardener::tests::object_storage::hp_secret_key'),
  $hp_auth_uri   = hiera('gardener::tests::object_storage::hp_auth_uri', 'https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/'),
  $hp_tenant_id  = hiera('gardener::tests::object_storage::hp_tenant_id', '10296473968402'),
  $hp_avl_zone   = hiera('gardener::tests::object_storage::hp_avl_zone', 'region-a.geo-1'),
) {
  include gardener::requirements

  $creds = {
      provider       => $provider,
      hp_access_key  => $hp_access_key,
      hp_secret_key  => $hp_secret_key,
      hp_auth_uri    => $hp_auth_uri,
      hp_tenant_id   => $hp_tenant_id,
      hp_avl_zone    => $hp_avl_zone,
  }
  file { '/tmp/sample.txt':
    content => 'This is a test for gardener::tests::object_storage'
  } ->
  # Creating a file in Cloud Storage
  object_storage {'myObjectStorage':
    ensure          => present,
    credentials     => $creds,
    provider        => hp,
    file_name       => 'sample.txt',
    remote_dir      => 'fog-rocks',
    local_dir       => '/tmp',
  } ->

  # Deleting a file in Cloud Storage
  object_storage {'myObjectStorage2':
    ensure          => absent,
    credentials     => $creds,
    provider        => hp,
    file_name       => 'sample.txt',
    remote_dir      => 'fog-rocks',
    local_dir       => '/tmp',
  }

}
