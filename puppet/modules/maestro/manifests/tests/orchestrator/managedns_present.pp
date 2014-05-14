# == maestro::tests::orchestrator::managedns_present
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
# Test creation of dns entries for default data.
#
#
class maestro::tests::orchestrator::managedns_present (
)
{
  class {'maestro::orchestrator::managedns':
    ensure           => present,
    instance_id      => 'jg',
    zone             => 'cdkdev.org',
    registered_email => 'test@cdkdev.org',
  }
}