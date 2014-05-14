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
    module ActionsZone
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

      # lookup node email
      def get_email
        return @resource[:email]
      end
      # lookup name for zone
      def get_zone
        return @resource[:name]
      end
      # lookup ttl for type
      def get_ttl
        return @resource[:ttl]
      end

      # create a new server
      def create
        Puppet.debug "starting create #{self.class.to_s}"
        dns_service = get_dns_service(get_zone)
        dns_service.create_zone(get_zone, get_email, get_ttl) if dns_service != nil
        Puppet.debug "done with create #{self.class.to_s}"
      end

      # destroy an existing server
      def destroy
        Puppet.debug "starting with destroy #{self.class.to_s}"
        dns_service = get_dns_service(get_zone)
        if dns_service != nil
          dnszone = dns_service.get_zone(get_zone)
          
          dns_service.remove_zone(dnszone.id)
        end
        Puppet.debug "done with destroy #{self.class.to_s}"
      end

      # check if a server exist
      def exists?
        Puppet.debug "Check if zone exist #{get_zone}"
        Puppet.debug "check email => #{get_email}"
        Puppet.debug "check ttl => #{get_ttl}"
        dns_service = get_dns_service(get_zone)
        return ((dns_service == nil ) ? false : dns_service.zone_exist?(get_zone))
      end
    end
  end
end
  
