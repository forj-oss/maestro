# Class: maestro::app::tool_status
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
# Installs a shell script
#
# Parameters:
# $directory:: An String with the directory path to install toolstatus.sh
# $user:: user String
# $group:: group string String
#

# Sample Usage:
# puppet apply -e "class { 'maestro::app::tool_status': }" --modulepath=/opt/config/production/git/maestro/puppet/modules:/etc/puppet/modules; --verbose
#

class maestro::app::tool_status(
  $directory = hiera('maestro::tool_status::directory','/usr/lib/forj'),
  $source    = hiera('maestro::tool_status::source','puppet:///modules/maestro/tool_status/maestro/toolstatus.sh'),
  $user      = hiera('maestro::tool_status::user','puppet'),
  $group     = hiera('maestro::tool_status::group','puppet'),
  $mode      = hiera('maestro::tool_status::mode','0555'),
){

  if !defined(File[$directory])
  {
    file { $directory:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => $mode,
      recurse => true,
    }
  }

  if !defined(File["${directory}/toolstatus.sh"])
  {
    file { "${directory}/toolstatus.sh":
      ensure  => present,
      owner   => $user,
      group   => $group,
      mode    => $mode,
      source  => $source,
      replace => true,
      require => File[$directory],
    }
  }
}
