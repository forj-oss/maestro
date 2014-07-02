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
#TODO: create specs / test directory and move this.
node /.*(review|precise32).*/  {

  include maestro::node_vhost_lookup
  if $hostname == 'precise32' {
    $paste_server = 'localhost'
  } else {
    $paste_server = $maestro::node_vhost_lookup::vname
  }

  $paste_vhost = $paste_server

  class { 'cdk_project::paste':
    sysadmins  => [],
    vhost_name => $paste_vhost,
    site_name  => 'cdkdev',
  }
}
