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

# load relative libraries
__LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)

require 'fog'      if Puppet.features.fog?
require "puppet/provider/pinasdns/loader" if Puppet.features.pinas?

module Puppet::Parser::Functions
  newfunction(:domain_record_exists, :type => :rvalue, :doc => <<-EOS
This function will determine if a domain record exist for the passed
in arguments.

To configure the fog provider a the following file must be present:
  /opt/config/fog/cloud.fog
  The path to the file can be controlled with environment argument FOG_RC.
  ie; export FOG_RC=/root/.fog/cloud.fog

  Provider definitions depend on the cloud version and provider you are 
  currently using.

*Arguments:*
  record     : record to look for
               FOG_RC is not configured, this will automatically return false.
  type       : record type to look for
*Examples:*
 
  domain_record_exists( $::fqdn, 'A' )

returns : true/false

    EOS
   ) do |args|
       Puppet.debug "in domain_record_exists.."
       unless  Puppet.features.fog?
         Puppet.warning "unable to continue, fog libraries are not ready, try running:
                       puppet agent --tags 'gardener::requirements'
                       or 
                       puppet apply --modulepath=\$PUPPET_MODULES -e 'include gardener::requirements'
                       returning false and skipping."
         return false
       end

       unless Puppet.features.pinas?
         Puppet.warning "Pinas common libraries unavailable, skip for this run."
         return false
       end

       # check for FOG_RC
       unless Puppet.features.fog_credentials?
         Puppet.warning "fog_credentials unavailable, skip for this run."
         return false
       end

       @loader = ::Pinas::DNS::Provider::Loader
       unless @loader.get_provider != nil
         Puppet.warning "Pinas fog configuration missing."
         return false
       end

       if (args.size != 2) then
          raise(Puppet::ParseError, "domain_record_exists: Wrong number of arguments "+
            "given #{args.size} for 1")
       end
       
       @fqdn = args[0]
       @type = args[1]
       allowed_types = [:A, :AAAA, :CNAME, :MX, :SRV, :TXT, 'A', 'AAAA', 'CNAME', 'MX', 'SRV', 'TXT']
       unless allowed_types.include? @type
         Puppet.err "dns record type not supported #{@type}...\n allowed types are #{allowed_types}."
         return false
       end
       
       @dnsservice = ::Pinas::DNS::Provider::DNS
       Puppet.debug("checking if record ( #{@fqdn}, #{@type} ) exists.")
       begin
        zone = @loader.parse_zone(@fqdn)
        dnss = @loader.get_dnss(zone)
        Puppet.debug "got dnss service."
        pinasdns = @dnsservice.instance(dnss)
        Puppet.debug  "got dns service."
       rescue Exception => e
         Puppet.debug "Error : #{e}"
         Puppet.warning "unable to find a valid domain for record lookup #{zone}"
         return false
       end
       return pinasdns.record_exist?(@fqdn, @type)
    end
end
