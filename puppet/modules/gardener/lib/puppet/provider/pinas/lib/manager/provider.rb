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
#
# provider determination from cloud.fog file
module Puppet
  module PinasProvider
    def get_provider
      cloud_info=get_cloud_info
      if ! cloud_info['forj'].nil? and ! cloud_info['forj']['provider'].nil? and ! cloud_info['forj']['provider'].empty?
        return cloud_info['forj']['provider']
      else
        Puppet.warning "pinas: FOG_RC='"+ENV["FOG_RC"]+"' does not define a provider section. Check for 'forj::provider' in fog file."
        return nil
      end
    end

    # version of the connection option to use
    def get_connection_version()
      cloud_info=get_cloud_info
      if ! cloud_info['default'].nil? and ! cloud_info['default']['version'].nil? and ! cloud_info['default']['version'].empty?
        Puppet.debug "using version from cloud_info section in default : #{cloud_info['default']['version']}"
        return cloud_info['default']['version'].to_sym
      end
    end
    
    # cloud info
    def get_cloud_info
        # Load /root/cloud.yaml
      # This file defines: 
      # - provider : FOG provider name. From FORJ, it must be 'HP', as using only hpcloud.
      cloud_file=get_fog_file
      if File.exist?(cloud_file)
         cloud_info=YAML.load_file(cloud_file)
      else
         Puppet.warning "FOG_RC defines a configuration file that is not found: #{cloud_file}"
         cloud_info= { "provider" => nil }
        end
        return cloud_info
    end

    def get_fog_file
      # always load FOG_RC
      if ENV["FOG_RC"].nil? 
         ENV["FOG_RC"]="/opt/config/fog/cloud.fog"
         Puppet.debug "Pinas: Using default setting for FOG_RC. FOG_RC='/opt/config/fog/cloud.fog'"
      else
         Puppet.debug "Pinas: Using YOUR 'FOG_RC' setting. FOG_RC='"+ENV["FOG_RC"]+"'"
      end
      return ENV["FOG_RC"]
    end
  end
end
