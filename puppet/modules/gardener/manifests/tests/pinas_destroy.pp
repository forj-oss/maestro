# == gardener::tests::pinas_destroy
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


class gardener::tests::pinas_destroy (
  $nodes       = ['pinasnode1','pinasnode2','pinasnode3'],
  $instance_id = '42',
  $threaded    = true,
  ) {

  pinas {'destroy openstack':
    ensure      => absent,
    instance_id => $instance_id,
    nodes       => $nodes,
    do_parallel => $threaded,
  }
}