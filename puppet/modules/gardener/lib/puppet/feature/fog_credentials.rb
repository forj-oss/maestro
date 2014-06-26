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
# check to see that the fog credentials are installed.
require 'yaml'
Puppet.features.add(:fog_credentials) do
  begin
    # lib
    Puppet.features.add(:yaml, :libs => ["yaml"])  # we flip on yaml configuration.
    Puppet.debug "yaml feature added"
    if ENV["FOG_RC"].nil? 
             ENV["FOG_RC"]="/opt/config/fog/cloud.fog"
    end
    fog_rc ENV["FOG_RC"]
    Puppet.debug "enabling feature check for fog_credentials on fog file => #{fog_rc}"
    if File.exist?(fog_rc)
      cloud_info=YAML.load_file(fog_rc)
      Puppet.debug "fog_credentials will be enabled with #{fog_rc}"
    else
      Puppet.warning "fog_credentials feature will not be enabled due to missing cred file: #{fog_rc}, set this with export FOG_RC."
    end
    true
  rescue Exception => err
    Puppet.warning "Problem with checking for feature fog_credentials: #{err}"
  end
end