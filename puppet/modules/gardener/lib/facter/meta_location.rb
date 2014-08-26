# == jimador::meta_location
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
# Find the location of the meta.js file on this system.
# if not exist, return empty.

#TODO: need to find how we can have this in a stdlib so we can just do require
def debug (msg = "")
  if Object.const_defined?('Puppet')
    Puppet.debug msg
  else
    if ENV['FACTER_DEBUG'] == 'true'
      $stdout.puts msg
      $stdout.flush
    end
  end
end

Facter.add("meta_location") do
  confine :kernel => "Linux"
  setcode do
    if File.exist? "/config/meta.js"
      Facter::Util::Resolution.exec("echo /config/meta.js")
    elsif File.exist? "/meta.js"
      Facter::Util::Resolution.exec("echo /meta.js")
    else
        Facter::Util::Resolution.exec("echo")
    end
  end
end

# When meta_location is defined, define all other facters
# that can be found in meta.js
if Facter.value('meta_location') != nil and Facter.value('meta_location') != ''
  require 'json'
  @meta_fspec = Facter.value('meta_location')
  @meta_data = JSON.parse(File.read(@meta_fspec))
  @meta_data.each_pair do |key, value|
    Facter.add(key) do
      setcode do
        if value != nil and value != ''
          Facter::Util::Resolution.exec("echo '#{value}'")
        else
          Facter::Util::Resolution.exec("echo")
        end
      end
    end
    debug "Added new Facter #{key} #{value}"
  end
end


