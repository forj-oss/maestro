# == jimador::puppet_url
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

Facter.add("rabbitmq_url") do
 confine :kernel => "Linux"
 setcode do
   begin
     http_name = Facter.value("helion_public_ipv4")
     ret = Facter::Util::Resolution.exec(Facter.value('forj_script_path') + 'toolstatus.sh rabbitmq')
     ret == '0' ? Facter::Util::Resolution.exec("echo http://#{http_name}:15672") : Facter::Util::Resolution.exec('echo')
   rescue Exception => e
     Facter.warn("Error at rabbitmq_url facter: #{e}")
     Facter::Util::Resolution.exec("echo #")
   end
 end
end
