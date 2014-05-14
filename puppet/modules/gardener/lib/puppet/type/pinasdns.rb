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
# a new type to work with garnder server nodes using fog api
# current goal is to provision a server with hp cloud
# we call this pinas because garnder's role is to create more nodes like 
# the agave pina

Puppet::Type.newtype(:pinasdns) do
  @doc = %q{Creates a new dns record
        A way to manage dns records in cloud environment.

        Example:
            include gardener::requirements
            
            pinasdns {'wiki.cdkdev.org.':
              ensure          => present,
              record_type     => 'A', # Possible values :A, :AAAA, :CNAME, :MX, :SRV, :TXT, 'A', 'AAAA', 'CNAME', 'MX', 'SRV', 'TXT',
              ip_data         => '192.168.0.5',
            }
      }
  feature :manage_record, "Ability to manage a dns record"
  feature :manage_zone,   "Ability to manage a dns zone"
  ensurable
  
# name of the dns record node
  newparam(:name) do
    desc "node name of the record."
  end

# When email is present, create a zone, not a record
  newparam(:email, :required_features => :manage_zone) do
    desc "email address to use to the zone name"
    # we should not have ip_data, set this to nil.
    # we should not have a record_type, set this to nil.
  end

# time to live, when record is updated, this is the time for dns to update in seconds.
  newparam(:ttl) do
    desc "time to live in seconds for dns updates to occur."
  end

# The provider name to use from the fog API.
#  newparam(:provider) do
#    desc "puppet provider to use for type."
#    defaultto :record
#    validate do |value|
#      Puppet.crit value
#      Puppet.crit value.class.to_s
#      Puppet.crit value.inspect
#    end
#  end

# set record_type
  newparam(:record_type, :required_features => :manage_record) do
    desc "Type of record to create."
    newvalues(:A, :AAAA, :CNAME, :MX, :SRV, :TXT, 'A', 'AAAA', 'CNAME', 'MX', 'SRV', 'TXT')
    defaultto :A
  end

# set the ip address
  newparam(:ip_data, :required_features => :manage_record) do
    desc "ip address data for the record."
  end
end
