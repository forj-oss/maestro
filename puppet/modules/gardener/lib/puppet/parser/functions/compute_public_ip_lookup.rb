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
require "puppet/provider/pinas/loader" if Puppet.features.pinas?

module Puppet::Parser::Functions
  newfunction(:compute_public_ip_lookup, :type => :rvalue, :doc => <<-EOS
This function will lookup the public ip address for a compute resource.

To configure the fog provider a the following file must be present:
  /opt/config/fog/cloud.fog
  The path to the file can be controlled with environment argument FOG_RC.
  ie; export FOG_RC=/root/.fog/cloud.fog

  Provider definitions depend on the cloud version and provider you are 
  currently using.
  
  The default provider is used for compute resource lookups.

*Arguments:*
  compute_name     : the name of the compute resource or id for the compute
                      resource.

*Examples:*
 
  compute_public_ip_lookup( 'pinasnode1' )

returns : '15.X.X.X'

When a compute resource is not found, the return value is ''

    EOS
   ) do |args|
       Puppet.debug "in compute_public_ip_lookup.."
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
       @loader = ::Pinas::Compute::Provider::Loader
       unless @loader.get_provider != nil
         Puppet.warning "Pinas fog configuration missing."
         return false
       end

       if (args.size != 1) then
          raise(Puppet::ParseError, "compute_public_ip_lookup: Wrong number of arguments "+
            "given #{args.size} for 1")
       end
       
       @compute_name = args[0]

       @compute_service = ::Pinas::Compute::Provider::Compute
       
       begin
        Puppet.debug("checking if compute node exist ( #{@compute_name} ) exists.")
        pinascompute = @compute_service.instance(@loader.get_compute)
        Puppet.debug  "got compute object."
       rescue Exception => e
         Puppet.err "unable to get compute service for #{@compute_name}"
         raise "unable to get compute service for #{@compute_name}"
       end
       return pinascompute.server_get_public_ip(@compute_name)
    end
end