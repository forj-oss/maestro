# == gardener::compute_vhost_name
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
# Provide a possible value for the vhost name that is used for an application
# we should also provide a method to set the value from env or other facter
# such as meta_vhostname
#
def checkdebug
  begin
    if ENV['FACTER_DEBUG'] == 'true'
      Facter.debugging(true)
    end
  rescue
  end
end

class String
  def is_empty?
    return (self == nil or self == "" or self.to_sym == :undefined)
  end
end

include ::Puppet::Forj::Facter if Puppet.features.factercache?

Facter.add("compute_vhost_name") do
  setcode do
    res = (!Puppet.features.factercache?) ? nil : Cache.instance().cache("compute_vhost_name") do
      checkdebug
      compute_vhost_name = String.new
      begin
        # use environment setting for COMPUTE_VHOST_NAME
        begin
          if compute_vhost_name.is_empty?
            env_compute_vhost_name = ENV['COMPUTE_VHOST_NAME']
            if env_compute_vhost_name != nil and env_compute_vhost_name != ''
              Facter.debug "using env_compute_vhost_name for vhost_name : #{env_compute_vhost_name}."
              compute_vhost_name = env_compute_vhost_name
              compute_vhost_name = compute_vhost_name.to_s if compute_vhost_name.class == Symbol
            end
          end
        rescue
          Facter.debug "env_compute_vhost_name lookup failed."
        end

        # check if the facter value meta_compute_vhost_name is configured
        begin
          if compute_vhost_name.is_empty?
            meta_compute_vhost_name = Facter.value('meta_compute_vhost_name')
            if meta_compute_vhost_name != nil and meta_compute_vhost_name != ''
              Facter.debug "using meta_compute_vhost_name for vhost_name : #{meta_compute_vhost_name}."
              compute_vhost_name = meta_compute_vhost_name
              compute_vhost_name = compute_vhost_name.to_s if compute_vhost_name.class == Symbol
            end
          end
        rescue
          Facter.debug "meta_compute_vhost_name lookup failed."
        end

        # calculate the vhostname from dns value being used
        if compute_vhost_name.is_empty?
          compute_dns_name = Facter.value('compute_dns_name')
          if compute_dns_name != nil and compute_dns_name != ''
            Facter.debug "using compute_dns_name for vhost_name : #{compute_dns_name}."
            compute_vhost_name = compute_dns_name
            compute_vhost_name = compute_vhost_name.to_s if compute_vhost_name.class == Symbol
          end
        end

        # calculate from public routable ip
        if compute_vhost_name.is_empty?
          compute_public_ip = Facter.value('compute_public_ip')
          if compute_public_ip != nil and compute_public_ip != ''
            Facter.debug "using compute_public_ip for vhost_name : #{compute_public_ip}."
            compute_vhost_name = compute_public_ip
            compute_vhost_name = compute_vhost_name.to_s if compute_vhost_name.class == Symbol
          end
        end

        # calculate from external service ip
        if compute_vhost_name.is_empty?
          helion_public_ipv4 = Facter.value('helion_public_ipv4')
          if helion_public_ipv4 != nil and helion_public_ipv4 != ''
            Facter.debug "using helion_public_ipv4 for vhost_name : #{helion_public_ipv4}."
            compute_vhost_name = helion_public_ipv4
            compute_vhost_name = compute_vhost_name.to_s if compute_vhost_name.class == Symbol
          end
        end

        compute_vhost_name = :undefined if compute_vhost_name == ""
      rescue Exception => e
        Facter.warn("compute_dns_name failed, #{e}")
        compute_vhost_name = :undefined
      end
      compute_vhost_name
    end
  end
end

