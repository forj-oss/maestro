# == gardener::tests::pinas_autosign
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
# testing the destroy process with pinas


class gardener::tests::pinas_autosign (
  $nodes           = ['pinasnode1','pinasnode2','pinasnode3'],
  $instance_id     = '42',
  $instance_domain = 'cdkdev.org',
  $key_access      = hiera('gardener::tests::pinas_autosign::key_access'),
  $secret          = hiera('gardener::tests::pinas_autosign::secret'),
  ) {
  include gardener::requirements

  $creds = {
        project_id => '10820682209898',
        user_name  => nil,
        key_access => $key_access,
        secret     => $secret,
        location   => 'az-3.region-a.geo-1',
  }

  pinas_autosign {$nodes:
    ensure          => present,
    instance_id     => $instance_id,
    instance_domain => $instance_domain,
    credentials     => $creds,
    provider        => puppet_hp,
    require         => Class['gardener::pinas_requirements'],
  }
}