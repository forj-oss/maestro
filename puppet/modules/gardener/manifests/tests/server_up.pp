# == gardener::tests::server_up
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
# test creating a server with server_up, who calls pinas
# image_name can also be a number like 48335

class gardener::tests::server_up (
  $nodes           = ['serverupnode1'],
  $instance_id     = '42',
  $instance_domain = 'cdkdev.org',
#  $image_name      = 'Ubuntu Precise 12.04 LTS Server 64-bit 20121026 (b)',
  $image_name      = 'proto2b',
) {
  class {'gardener::params':
      image_name   => $image_name,
      # can also be a number like 100
      flavor_name  => 'standard.xsmall',
      key_name     => 'nova',
      network_name => 'private',
  } ->
  class {'gardener::server_up':
      nodes           => $nodes,
      instance_id     => $instance_id,
      instance_domain => $instance_domain,
      do_threaded     => false,
  }
}
