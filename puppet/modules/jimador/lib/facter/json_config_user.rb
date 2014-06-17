# == maestro_ui::maestro_ui_owner
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
# The user that is running the puppet agent on this box
Facter.add("json_config_user") do
 confine :kernel => "Linux"
 setcode do
   # TODO: determine a way for how the puppet master runs manifest on the agents.
   # under what user account?   otherwise provide some configuration file for this.
   Facter::Util::Resolution.exec("echo puppet")
 end
end