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
# actions that the custom type will take
module Pinas
  module DNS
    module ActionsRecord
      def get_dns_service(fqdn)
        @loader = ::Pinas::DNS::Provider::Loader
        @dnsservice = ::Pinas::DNS::Provider::DNS
        pinasdns = nil
        begin
          zone = @loader.parse_zone(fqdn)
          dnss = @loader.get_dnss(zone)
          pinasdns = @dnsservice.instance(dnss)
        rescue Exception => e
           Puppet.warning "unable to find a valid domain for record lookup #{zone}"
           return nil
        end
        return pinasdns
      end

      # lookup node ip
      def get_ip
        return @resource[:ip_data]
      end
      # lookup name for type
      def get_fqdn
        return @resource[:name]
      end
      # lookup recordd_type for type
      def get_type
        return @resource[:record_type]
      end

      # create a new server
      def create
        Puppet.debug "starting create #{self.class.to_s}"
        dns_service = get_dns_service(get_fqdn)
        dns_service.create_record(get_fqdn, get_type, get_ip)  if dns_service != nil
        Puppet.debug "done with create #{self.class.to_s}"
      end

      # destroy an existing server
      def destroy
        Puppet.debug "starting with destroy #{self.class.to_s}"
        dns_service = get_dns_service(get_fqdn)
        if dns_service != nil
          dnsrecord = dns_service.get_record(get_fqdn, get_type)
          dns_service.remove_record(dnsrecord.hash_id)
        end
        Puppet.debug "done with destroy #{self.class.to_s}"
      end

      # check if a server exist
      def exists?
        Puppet.debug "using provider action_record"
        Puppet.debug "starting exists? #{self.class.to_s}"
        Puppet.debug "check name => #{get_fqdn}"
        Puppet.debug "check type => #{get_type}"
        dns_service = get_dns_service(get_fqdn)
        return false if dns_service == nil
        return dns_service.record_exist?(get_fqdn, get_type)
      end
    end
  end
end
  
