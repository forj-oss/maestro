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

# reach out to the gerrit registration services and identify the email 
# address for this kit.  relys on facter for registration endpoints.

__LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)

# load net_helper libraries
include ::Puppet::ForjCommon if Puppet.features.forj_common?
include ::Puppet::Forj if Puppet.features.net_helper?


module Puppet::Parser::Functions
  newfunction(:kit_registration_lookup, :type => :rvalue, :doc => <<-EOS
This function should be used when trying to determine who the kit 
 is registered to.

*Facters:*
  maestro_id : the id for the kit to lookup (should only be looking up it's own)
  gitbranch  : the branch this endpoint is for, so we can find it from nodejs app

*Examples:*
 
  kit_registration_lookup()

returns : email@domain

When kit registration is not found, returns ''

    EOS
   ) do |args|
       Puppet.debug "calling kit_registration_lookup.."
       registered_to = ''
       unless  Puppet.features.net_helper?
         Puppet.warning "unable to continue, net_helper libs not loaded, skipping."
         return registered_to
       end
       
       # determine what the maestro_id is
       maestro_id = lookupvar('maestro_id') 
       # determine what branch we're on registration_endpoint
       registration_endpoint = lookupvar('registration_endpoint')
       Puppet.debug "using registration endpoint #{registration_endpoint}"
       reg_search_uri = nil
       begin
         reg_search_uri = URI.parse("#{registration_endpoint}/search/instance_id")
       rescue Exception => e
         Puppet.debug "unable to continue with lookup, bad uri : #{reg_search_uri}"
         return registered_to
       end
       result = nil
       begin
          utilurl = UtilURI.new
          # result = utilurl.open_jsonurl("#{reg_search_uri}/#{maestro_id}", '200')
          Puppet.debug "open_jsonurl => #{reg_search_uri}/#{maestro_id}"
          result = utilurl.open_jsonurl("#{reg_search_uri}/#{maestro_id}", '200')
          Puppet.debug "got an empty result, no data on #{reg_search_uri}/#{maestro_id}" if result == nil
          registered_to = ""
          if result != nil and result['result'].length > 0 and result['result'][0].has_key?('email')
            registered_to = result['result'][0]['email']
          end
           
        rescue Timeout::Error => detail
         Puppet.debug "Error in contacting #{reg_search_uri}/#{maestro_id}: #{detail}"
         registered_to = ""
        rescue Exception => e
            Puppet.debug "other exception, unable to get data from connection, #{e}"
            registered_to = ""
        end
       registered_to.to_s
    end
end