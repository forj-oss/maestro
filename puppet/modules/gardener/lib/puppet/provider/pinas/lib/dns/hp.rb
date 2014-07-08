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
# common implementation class for server management under pinas
require 'hpcloud/base_helper'
require 'hpcloud/cli_status'
require 'hpcloud/dnss'

module Puppet
  module PinasDNSHP
    # HP Provider specific methods
    # build a compute fog object
    def get_dns()
      Puppet.debug "in get_dns hp"
      if get_provider != nil
         begin
            Manager::HP::Connection.instance(:dns) # we read the :dns section from fog file and setup hpcloud cli to use it
            #TODO: This method calls Fog::HP::DNS.new(opts) only... for other providers, we'll need to implement simillar api call methods.
            dns_conn = HP::Cloud::Connection.instance.dns # now we can use hpcloud cli api to get a dns object
            return {:dns => dns_conn, :dnss => nil, :dnsh => nil }
         rescue Exception => e
            Puppet.warning "problem getting Manager::HP::Connection.instance, #{e}"
            Puppet.crit e.backtrace.join("\n")
           raise "problem getting Manager::HP::Connection.instance, #{e}"
         #  return {:dns => nil, :dnss => nil, :dnsh => nil }
         end
      else
         raise "Puppet::PinasDNSHP::get_dns FOG_RC='"+ENV["FOG_RC"]+"' does not define a FOG provider. Check 'forj/provider' declaration."
         return {:dns => nil, :dnss => nil, :dnsh => nil }
      end
    end
    
    # return a dns service object based on the zone name
    # we use this to get records and manage records
    def get_dnss(name_or_id = nil)
      @connection = ::HP::Cloud::Connection.instance  # note, Dnss relies on @connection being defined to use.
      dns = self.get_dns # setup the local account first
      if name_or_id == nil
        dnss = ::HP::Cloud::Dnss.new
      else
        dnss = ::HP::Cloud::Dnss.new.get(name_or_id)
        if dnss.is_valid? == false
          raise "Puppet::PinasDNSHP::get_dnss #{name_or_id} is not valid. #{dnss.cstatus}"
        end
      end
      # setup a helper to manage zone records
      dnshelper = HP::Cloud::DnsHelper.new(HP::Cloud::Connection.instance)
      return {:dns => dns[:dns], :dnss => dnss, :dnsh => dnshelper }
    end

  end
end
