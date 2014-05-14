# == maestro_ui::maestro_configfile
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
# Location of the configuration file for config.json
#TODO: find if we can remove this facter.

#TODO: depricate
Facter.add("maestro_configfile") do
 confine :kernel => "Linux"
 setcode do
   rootdir     = Facter.value('maestro_ui_rootdir')
   config_json = File.join(rootdir, 'ero-ui/config/config.json')
   Facter::Util::Resolution.exec("echo #{config_json}")
 end
end
