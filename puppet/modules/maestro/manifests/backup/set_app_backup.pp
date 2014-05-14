# Class: maestro::backup::set_app_backup
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
class maestro::backup::set_app_backup(
  $app_name    = hiera('maestro::backup::set_app_backup::app_name'  , ''   ),
  $app_folder  = hiera('maestro::backup::set_app_backup::app_folder', ''   ),
  $bkp_name    = hiera('maestro::backup::set_app_backup::bkp_name'  , ''   ),
  $use_db      = hiera('maestro::backup::configure_box::uses_db'    , false),
  $db_user     = hiera('maestro::backup::box_db_user'               , ''),
  $db_password = hiera('maestro::backup::box_db_password'           , ''),
) {

  include maestro::backup::params

  $ssh_name=$maestro::backup::params::backup_user

  if ($app_name   == undef or $app_name   == '' or
      $app_folder == undef or $app_folder == '' or
      $bkp_name   == undef or $bkp_name   == '' ) {
    notify{"ERROR, one more parameters are empty,
            can't proceed with ${app_name} backup configuration.":}
  }
  else  {
    if ($use_db      == true and
        ( $db_user     == undef or $app_folder == '' or
          $db_password == undef                        )) {
      notify{'ERROR, uses database, but no user and password is configured':}
    }
    else {

      $conf_fullpath = "${maestro::backup::params::box_conf_folder}/conf.d"
      file { "${conf_fullpath}/bkp_${app_name}.conf":
        ensure  => file,
        mode    => '0400',
        content => template('maestro/backup/config.erb'),
        require => File[$conf_fullpath],
      }->
      notify{"Installed backup config file: bkp_${app_name}.conf":}
    }
  }
}

