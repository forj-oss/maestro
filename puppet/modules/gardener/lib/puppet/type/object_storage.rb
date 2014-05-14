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

Puppet::Type.newtype(:object_storage) do
  @doc = %q{ Uses fog api to handle block storage.

        Example:
            include gardener::block_storage
            
            $creds = {
                hp_access_key => 'TCCNELDJ3KRH66KAF7K5',
                hp_secret_key => 'GRrvOvSH9mkqZ9aEwp0dh4Aagk7HF2/6zZT9qHIu',
                hp_auth_uri   => 'https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/',
                hp_tenant_id  => '10296473968402',
                hp_avl_zone   => 'az-3.region-a.geo-1',
             }
  
            block_storage {'MyBlockStorage':
              credentials     => $creds,              
              provider        => hp,
            }
      }  
  
  ensurable
  
  newparam(:name) do
    desc "identifier name."
  end

  # these are the credentials to use for the cloud provider
  # TODO: ChL: This file has currently not been updated related to credentials. But normally, any fog task uses /root/.fog. credentials should not exist in puppet files anymore.
  newparam(:credentials) do
    desc "a hash that contains the cloud provider credentials."
    creds_sym = {}
    munge do |value|
      value.each do |key, item|
        creds_sym[key.to_sym]=item
      end
      creds_sym
    end
  end

  
  newparam(:provider) do
    desc "Supported cloud providers (Currently just HP is supported)."    
  end  
  
  newparam(:file_name) do
    desc "File name and extension"
  end
  
  newparam(:remote_dir) do
    desc "Cloud directory"
  end
  
  newparam(:local_dir) do
    desc "Local directory (Unix format)"
  end
  
end
