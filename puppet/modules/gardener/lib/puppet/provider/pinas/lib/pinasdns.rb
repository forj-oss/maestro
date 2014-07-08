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
# driver class for fog

require 'fog' if Puppet.features.fog?

module Puppet
  module Pinas
    class DNS
      attr_accessor :dns
      attr_accessor :dnss
      attr_accessor :dnsh
      # singleton call:
      def self.instance(comm)  # use this instead of .new!! to get a singleton
        @@pinasdns ||= self.new(comm)
        @@pinasdns.dns = comm[:dns] if comm.has_key?(:dns)
        @@pinasdns.dnss = comm[:dnss] if comm.has_key?(:dnss)
        @@pinasdns.dnsh = comm[:dnsh] if comm.has_key?(:dnsh)
        return @@pinasdns
      end

      # to keep our routines simple, we encrypt it also   (needs to be tested... :D)
      def initialize(comm)
        Puppet.debug("creating new object Puppet::PinasDNS")
        @dns  = comm[:dns]
        @dnss = comm[:dnss]
        @dnsh = comm[:dnsh]
      end

      # lookup a dns name by ip, if we find a mapped ip, give us the name.
      #
      # @params string [String] the ip address to find the record for
      # @return string [String] the dns name mapping the ip address
      def reverse_name_lookup(ip, type = :A)
        # look for all the zones
        type = type.to_sym if type.class != Symbol
        dns_name = String.new
        @dns.domains.each do |zone|
          @dns.domains.get(zone.id).records.each do | record |
            dns_name = record.name if record.data == ip and record.type.to_sym == type
          end
        end
        return dns_name
      end

      # create a dns record
      def create_record(fqdn, type, ipdata)
        unless @dnss.is_valid?
          Puppet.crit dns.cstatus
        end
        priority = {} # TODO: research how to implement priority for puppet
#        priority = priority[0]
#        if priority.nil?
#           priority = {}
#        else
#           priority = { :priority => priority.to_i }
#        end
        record = @dnss.create_record(fqdn, type, ipdata, priority)
        if record.nil?
          Puppet.err dns.cstatus
        end
        Puppet.notice "Created dns record '#{fqdn}' with id '#{record[:id]}'."
      end

      def remove_record(id)
        unless @dnss.is_valid?
          Puppet.crit dns.cstatus
        end
        if @dnss.delete_record(id)
          Puppet.notice "Removed DNS record '#{id}'."
        else
          Puppet.err "Cannot find DNS record '#{id}'."
        end
      end
      # get list of managed dns names
      # does dns name exist 
      def zone_exist?(name)
        match =  find_match(@dns.domains, name)
        if match != nil
          Puppet.notice "found dns zone #{match.name}"
          return true
        else
          Puppet.debug "zone not found : #{name}"
          return false
        end
      end

      # determine if record exists
      def record_exist?(fqdn, type)

        matches = find_match(@dnss.records, fqdn, true)
        if matches != nil
          record = nil
          matches.each do |record|
            Puppet.debug "inspecting #{record.hash_type} == #{type}"
            if record.hash_type.to_s == type.to_s
              Puppet.notice "found dns record :  #{fqdn}, #{type}"
              return true
            end
          end
        else
          Puppet.debug "match found no record : #{fqdn}, #{type}"
        end
        Puppet.debug "record not found : #{fqdn}, #{type}"
        return false
      end

      # get a dns record object
      def get_record(fqdn, type)
        matches = find_match(@dnss.records, fqdn, true)
        if matches != nil
          record = nil
          matches.each do |record|
            Puppet.debug "inspecting #{record.hash_type} == #{type}"
            if record.hash_type.to_s == type.to_s
              Puppet.notice "found dns record :  #{fqdn}, #{type}"
              return record
            end
          end
        else
          Puppet.debug "match found no record : #{fqdn}, #{type}"
        end
        Puppet.debug "record not found : #{fqdn}, #{type}"
        return nil
      end

      # create a dns zone
      def create_zone(zone, email, ttl)
        @dnsh.name  = zone
        @dnsh.email = email
        @dnsh.ttl   = ttl
        if @dnsh.save == true
          Puppet.notice "Created dns zone #{zone} with id #{@dnsh.id}"
        else
          Puppet.err @dnsh.cstatus
          raise @dnsh.cstatus
        end
      end

      # remove a dns zone
      def remove_zone(zone_or_id)
        zone = get_zone(zone_or_id)
        # destroy the zones
        Puppet.notice "removing zone #{zone.name}"
        Puppet.debug "zone.name => #{zone.name}"
        Puppet.debug "zone.id   => #{zone.id}"
        zone.destroy
        if zone_exist?(zone_or_id)
          Puppet.err "Failed to remove zone => #{zone_or_id}"
          raise "Failed to remove zone => #{zone_or_id}"
        end
      end

      # get a dns zone
      def get_zone(zone)
        return find_match(@dns.domains, zone)
      end
    end
  end
end