# == maestro::kitops_endpoint
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
# identify if the kitops endpoint is enabled on maestro
# and if it's accessible from the node.
# if the endpoint is not availble return a null response.
# if the endpoint is enabled, then define all of the factors for the endpoint.
#
# this script will create facters for all values in kitops/options
# can use facter kitops_proxy  { true or false }
# can use facter kitopsip to specify the location of kitops service
# can use facter eroip when kitopsip is not available.
# set's kitops_endpoint when the service is available, use this key to 
# take actions on.
#
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

include ::Puppet::ForjCommon if Puppet.features.forj_common?
include ::Puppet::Forj if Puppet.features.net_helper?
#
# define facter 
#
Facter.add("kitops_endpoint") do
 setcode do
    utilurl = UtilURI.new
    kitops_uri = nil
    debug "kitops_endpoint definition"
    kitops_ip = Facter.value('kitopsip')
    debug("kitops_ip is => #{kitops_ip}")
    if kitops_ip == nil or kitops_ip == ""
      m_ip   = Facter.value('eroip')
    else
      m_ip   = kitops_ip
    end
    debug "working with m_ip = #{m_ip}"
    # communicate to m_ip:8080/kitops/ping
    # if pong response, then set url, otherwise don't set
    if m_ip != "" and m_ip != nil
      begin
        kitops_uri = URI.parse("http://#{m_ip}:8080/kitops")
      rescue Exception => e
        debug("Problem with parsing URI http://#{m_ip}:8080/kitops, #{e.message}")
        kitops_uri =  ""
      end
    end
#    
    if kitops_uri != ""
      begin
        debug("checking url #{kitops_uri}/ping")
        result = utilurl.open_jsonurl("#{kitops_uri}/ping", '200', (Facter.value('kitops_proxy') == 'true') ? true : false)
        debug("got an empty result, no data on #{kitops_uri}")   if result == nil
        kitops_uri = ""                if result == nil
        debug("/ping url is not pong #{result['status']}") if result != nil and result['status'] != "pong"
        kitops_uri = ""                if result != nil and result['status'] != "pong"
      rescue Timeout::Error => detail
       debug( "Error in contacting #{kitops_uri}/ping: #{detail}")
       kitops_uri = ""
      rescue Exception => e
        debug("other exception, unable to get data from connection, #{e}")
        kitops_uri = ""
      end
    end
    kitops_uri.to_s
 end
end

# define api url facters
if Facter.value('kitops_endpoint') != nil and Facter.value('kitops_endpoint') != '' 
   #
   # build all facters for kitops service
   #
   def build_kitops_facters(api_url = nil)
     utilurl = UtilURI.new
     return if api_url == nil
     result = utilurl.open_jsonurl("#{api_url}/options", '200', (Facter.value('kitops_proxy') == 'true') ? true : false)
     if result != nil
       debug("got options #{result}")
       create_optionstofacter(result)
     else
       debug("no options found")
     end
   end
   # recursivley add each option to facter
   def create_optionstofacter(arr_hf = [])
     if arr_hf.is_a?(Array)
       hf  = arr_hf.first
       if hf != nil and hf.has_key? 'option_name'
         key = hf['option_name'] 
         val = hf['option_value']
         create_facter(key, val)
       end
       if arr_hf.length > 0
         arr_hf = arr_hf.drop(1)
         create_optionstofacter(arr_hf)
       end
     end
   end
   # create a single facter value
   def create_facter(key = nil, val = '')
     if key != nil
       Facter.add(key) do
           setcode do
             if val != nil and val != ''
               Facter::Util::Resolution.exec("echo #{val}")
             else
               Facter::Util::Resolution.exec("echo")
             end
           end
        end
        debug "Added new Facter #{key} #{val}"
     end
   end
 
   build_kitops_facters Facter.value('kitops_endpoint')
end
