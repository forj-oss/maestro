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
# Use pinas compute lib to lookup dns name by public ip

def checkdebug
  begin
    if ENV['FACTER_DEBUG'] == 'true'
      Facter.debugging(true)
    end
  rescue
  end
end

require 'fog'      if Puppet.features.fog?
require "puppet/provider/pinasdns/loader" if Puppet.features.pinas?

include ::Puppet::Forj::Facter if Puppet.features.factercache?

Facter.add("compute_dns_name") do
  setcode do
    res = (!Puppet.features.factercache?) ? nil : Cache.instance().cache("compute_dns_name") do
      checkdebug
      compute_dns_name = String.new
      isready = true
      begin
        public_ip = Facter.value('compute_public_ip')
        if (public_ip == nil or public_ip == '') and isready == true
          Facter.warn "unable to continue without compute_public_ip facter"
          isready = false
        end
        Facter.debug "looking up compute dns name with #{public_ip}"

        # verify fog libraries can be loaded
        if !Puppet.features.fog? and isready == true
          Facter.warn "fog not loaded, compute_public_ip empty"
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

        if isready
          # load the compute object
          @loader = ::Pinas::DNS::Provider::Loader
          if @loader.get_provider == nil and isready == true
            Facter.warn "Pinas fog configuration missing."
            isready = false
          end
          Facter.debug "using provider #{@loader.get_provider}"

          # compute service
          @dnsservice = ::Pinas::DNS::Provider::DNS
          dnss = @loader.get_dnss
          pinasdns = @dnsservice.instance(dnss)
          compute_dns_name = pinasdns.reverse_name_lookup(public_ip)
          compute_dns_name = compute_dns_name.gsub(/\.$/,'')
          compute_dns_name = :undefined if compute_dns_name == ""
        else
          compute_dns_name = :undefined
        end
      rescue Exception => e
        Facter.warn("compute_dns_name failed, #{e}")
        compute_dns_name = :undefined
      end
      compute_dns_name
    end
  end
end

