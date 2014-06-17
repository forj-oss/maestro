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
# provide default or custom definitions for node type
# nodetype allows us to select what classes/packages to install from hieradata

Facter.add(:fog) do
  setcode do
    if ENV["FOG_RC"].nil? 
       ENV["FOG_RC"]="/opt/config/fog/cloud.fog"
    end

    fog_rc=ENV["FOG_RC"]
    
    if File.file?(fog_rc)
       fog_rc
    else
       "UNDEF"
    end
  end
end

