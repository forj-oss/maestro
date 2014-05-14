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
module Puppet
  module PinasNetworkHP
    # HP Provider specific methods
    # build a compute fog object
    def get_network(template = nil)
     network_name = get_network_name(template)
     if network_name == nil or network_name == ''
       Puppet.warning "Fog::Network can not be used!! please upgrade fog api provider info and provide network_name"
       return nil
     end
     if get_provider != nil
        compute_creds = {
              :provider => get_provider,
              :connection_options => get_connection_options
            }
        conn = Fog::Network.new( compute_creds )
        return conn
     else
        raise "Puppet::PinasNetworkHP::get_network FOG_RC='"+ENV["FOG_RC"]+"' does not define a FOG provider. Check 'forj/provider' declaration."
        return nil
     end
    end

    # get the network_name from template
    def get_network_name(template)
      return nil if template == nil
      return ((template.has_key?(:network_name) ? template[:network_name] : nil))
    end
  end
end
