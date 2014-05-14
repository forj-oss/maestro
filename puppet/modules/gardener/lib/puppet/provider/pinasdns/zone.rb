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
# manage a server node using fog
# our default provider implements on hp cloud
# we add additional providers based on this one

# fog.io/dns

require 'fog' if Puppet.features.fog?
require 'json' if Puppet.features.json?
require "puppet/provider/pinasdns/loader" if Puppet.features.pinas?
require 'puppet/provider/pinasdns/actions_zone' if Puppet.features.pinas?

Puppet::Type.type(:pinasdns).provide(:zone) do
  desc "Creates hp dns type for Gardner."
  has_feature :manage_zone
  confine :feature => :fog
  confine :feature => :json
  confine :feature => :pinas
  Puppet.debug("loaded provider manage_zone")
  include ::Pinas::DNS::ActionsZone
  include ::Pinas::DNS::Provider
end
