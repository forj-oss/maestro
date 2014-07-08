# == gardener::puppetmaster
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
# Use pinas compute lib to lookup dns name by public ip

def checkdebug
  begin
    if ENV['FACTER_DEBUG'] == 'true'
      Facter.debugging(true)
    end
  rescue
  end
end



Facter.add("puppetmaster") do
  setcode do
    master_name = String.new
    begin
      def get_vhost
        this_server = Facter.value('compute_vhost_name')
        if (this_server == nil or this_server == "" or this_server.to_sym == :undefined)
          this_server = Facter.value('helion_public_ipv4')
        end
        if (this_server == nil or this_server == "" or this_server.to_sym == :undefined)
          this_server = Facter.value('fqdn')
        end
        this_server
      end
      puppet_conf = (ENV['PUPPET_CONF'] == nil or ENV['PUPPET_CONF'] == '') ? '/etc/puppet/puppet.conf' : ENV['PUPPET_CONF']
      if File.exist? puppet_conf
        data = File.open(puppet_conf)
        is_found = nil
        until data.eof() or is_found != nil
          is_found = /\[master\]/.match(data.readline)
          master_name = get_vhost if is_found != nil
        end
      end
    rescue Exception => e
      Facter.warn("compute_dns_name failed, #{e}")
      master_name = String.new
    end
    master_name
  end
end

