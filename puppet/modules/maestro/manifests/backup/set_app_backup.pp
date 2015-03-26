# Define: maestro::backup::set_app_backup
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
define maestro::backup::set_app_backup(
  $applications
) {
  $app_name           = $name
  $app_location       = $applications[$name]['app_location']
  $exclude            = $applications[$name]['exclude']
  $db_backup_tool     = $applications[$name]['db_backup_tool']
  $db_name            = $applications[$name]['db_name']
  $db_user            = $applications[$name]['db_user']
  $db_password        = $applications[$name]['db_password']

  include maestro::backup::params

  $ssh_config_name=$maestro::backup::params::backup_user

  if ($db_name  != '')
  {
    if ($db_user == undef or $db_user == '' )
    {
      fail("ERROR, db user name for ${name} application is required.")
    }
    if ($db_password == undef or  $db_password == '')
    {
      fail("ERROR, db user password for ${name} application is required.")
    }
  }
  $conf_fullpath = "${maestro::backup::params::box_conf_folder}/conf.d"
  file { "${conf_fullpath}/bkp_${app_name}.conf":
    ensure  => file,
    mode    => '0400',
    content => template('maestro/backup/config.erb'),
    require => File[$conf_fullpath],
  }->
  notify{"Installed backup config file: bup_${app_name}.conf":}
}