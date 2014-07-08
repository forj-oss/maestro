# == gardener::compute_id_lookupbyip
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
# Use pinas compute lib to lookup compute id by ip address

def checkdebug
  begin
    if ENV['FACTER_DEBUG'] == 'true'
      Facter.debugging(true)
    end
  rescue
  end
end

require 'fog'      if Puppet.features.fog?
require "puppet/provider/pinas/loader" if Puppet.features.pinas?

include ::Puppet::Forj::Facter if Puppet.features.factercache?

Facter.add("compute_id_lookupbyip") do
  setcode do
    res = (!Puppet.features.factercache?) ? nil : Cache.instance().cache("compute_id_lookupbyip") do
      checkdebug
      compute_id = String.new
      isready = true
      begin
        ipaddress = Facter.value('ipaddress')
        if (ipaddress == nil or ipaddress == '') and isready == true
          Facter.warn "unable to continue without ipaddress facter"
          isready = false
        end
        Facter.debug "looking up compute id with #{ipaddress}"

        # verify fog libraries can be loaded
        if  !Puppet.features.fog? and isready == true
          Facter.warn "fog not loaded, compute_id_lookup empty"
          isready = false
        end

        # verify pinas common lib is available
        if !Puppet.features.pinas? and isready == true
          Facter.warn "pinas common lib unavailable."
          isready = false
        end

        # verify fog_rc file found
        if !Puppet.features.fog_credentials? and isready == true
          Facter.warn "fog_credentials unavailable, set FOG_RC"
          isready = false
        end

        if isready == true
          # load the compute object
          @loader = ::Pinas::Compute::Provider::Loader
          if @loader.get_provider == nil and isready == true
            Facter.warn "Pinas fog configuration missing."
            isready = false
          end
          Facter.debug "using provider #{@loader.get_provider}"

        # compute service
          @compute_service = ::Pinas::Compute::Provider::Compute
          pinascompute = @compute_service.instance(@loader.get_compute)
          compute_id = pinascompute.get_server_id_by_private_ip(ipaddress)
          compute_id = :undefined if compute_id == ""
        else
          compute_id = :undefined
        end
      rescue Exception => e
        Facter.warn("compute_id_lookupbyid failed, #{e}")
        compute_id = :undefined
      end
      compute_id
    end
  end
end

