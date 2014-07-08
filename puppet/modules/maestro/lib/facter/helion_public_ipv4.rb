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

#
# depends on:
# https://community.hpcloud.com/article/get-public-ip-within-instance
#
require 'uri'
require 'net/http'
require 'openssl'
require 'json'       if Puppet.features.json?

include ::Puppet::ForjCommon if Puppet.features.forj_common?
include ::Puppet::Forj if Puppet.features.net_helper?
include ::Puppet::Forj::Facter if Puppet.features.factercache?
#
# define facter
#
Facter.add('helion_public_ipv4') do
  setcode do
    def public_ipv4
      begin
        public_ipv4_url = 'http://169.254.169.254/latest/meta-data/public-ipv4'
        utilurl = UtilURI.new
        ipv4 = utilurl.openurl(public_ipv4_url, code = '200', use_proxy = false, timeout = 15)
      rescue Timeout::Error => detail
        debug("Error in contacting #{public_ipv4_url}: #{detail}")
        ipv4 = String.new
      rescue Exception => e
        debug("other exception, unable to get data from connection, #{e}")
        ipv4 = String.new
      end
      ipv4
    end
    res = (!Puppet.features.factercache?) ? public_ipv4 : Cache.instance().cache("helion_public_ipv4") do
      public_ipv4
    end
  end
end
