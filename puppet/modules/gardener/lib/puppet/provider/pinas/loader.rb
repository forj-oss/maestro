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
# we want to identify the correct library to load outside
# a provider, so we use the fog provider to load the correct library

if Puppet.features.pinas?
  require 'puppet/provider/pinas/lib/common'
  require 'puppet/provider/pinas/lib/manager/provider'
  require 'puppet/provider/pinas/lib/pinascompute'
end

module Pinas
  module Compute
    module Provider
      if Puppet.features.pinas?
        include ::Pinas::Common
        include ::Puppet::PinasProvider
      end
      class Compute < ::Puppet::Pinas::Compute # for pinas/lib/pinascompute gives Compute class
        if Puppet.features.pinas?
          include ::Pinas::Common
          include ::Puppet::PinasProvider
        end
      end
      class Loader
        if Puppet.features.pinas?
          extend ::Pinas::Common
          extend ::Puppet::PinasProvider
          Puppet.debug("loading Pinas::Compute::Provider::Loader...")
          case get_provider
          when :hp, "hp", :openstack, "openstack"
            require 'puppet/provider/pinas/lib/compute/hp'
            require 'puppet/provider/pinas/lib/network/hp'
            extend ::Puppet::PinasComputeHP
            extend ::Puppet::PinasNetworkHP
            
            Puppet.debug "loadded Pinas::Compute::Provider::Loader for #{get_provider}"
          else
            raise "Pinas::Compute::Provider::Loader does not support this provider in #{get_provider}."
          end
          
        end

        def initialize
        end
      end
    end
  end
end


