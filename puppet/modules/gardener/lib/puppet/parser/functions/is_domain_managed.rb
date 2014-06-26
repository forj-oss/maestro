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
  newfunction(:is_domain_managed, :type => :rvalue, :doc => <<-EOS
This function will determine if a domain name provided is or is not managed
 with the current fog provider configured for this system.
To configure the fog provider a the following file must be present:
  /opt/config/fog/cloud.fog
  The path to the file can be controlled with environment argument FOG_RC.
  ie; export FOG_RC=/root/.fog/cloud.fog

  Provider definitions depend on the cloud version and provider you are 
  currently using.

*Arguments:*
  domain     : The domain name to check if it's managed
               FOG_RC is not configured, this will automatically return false.
*Examples:*
 
  is_domain_managed( $::domain )

returns : true/false

    EOS
   ) do |args|
      Puppet.debug "in is_domain_managed.."
      unless  Puppet.features.fog?
        Puppet.warning "unable to continue, fog libraries are not ready, try running:
                      puppet agent --tags 'gardener::requirements'
                      or 
                      puppet apply --modulepath=\$PUPPET_MODULES -e 'include gardener::requirements'
                      returning false and skipping."
        return :undefined
      end

      unless Puppet.features.pinas?
        Puppet.warning "Pinas common libraries unavailable, skip for this run."
        return :undefined
      end

      # check for FOG_RC
      unless Puppet.features.fog_credentials?
        Puppet.warning "fog_credentials unavailable, skip for this run."
        return :undefined
      end

      @loader = ::Pinas::DNS::Provider::Loader
      unless @loader.get_provider != nil
        Puppet.warning "Pinas fog configuration missing."
        return :undefined
      end

      if (args.size != 1) then
         raise(Puppet::ParseError, "is_domain_managed: Wrong number of arguments "+
           "given #{args.size} for 1")
      end
       
      @domain = args[0]
      @dnsservice = ::Pinas::DNS::Provider::DNS
      Puppet.debug("checking if domain ( #{@domain} ) is managed.")
      begin
        pinasdns = @dnsservice.instance(@loader.get_dns)
        return pinasdns.zone_exist?(@domain)
      rescue Exception => e
        Puppet.warning "unable to check if domain is manged."
        return :undefined
      end
    end
end