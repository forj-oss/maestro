# Class: maestro::app::run_ddl
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
# Execute a ddl script
#
# Parameters:
# $mysql_server::     An String, example localhost
# $mysql_user::       The root user to use.
# $mysql_password::   The root password to use for running the create scripts.
# $mysql_user::       The application user to use in erb files.
# $mysql_password::   The application password to use in erb files.
# $ddl_name:: / $title An String with sql ddl file
# $ddl_source:: source location of the ddl script
# $ddl_content:: we use this to read template data instead of source data.
# $ddl_home_dir location on local server for ddl files.
#
# Actions:
# (1) Connects to mysql and executes a script

# Sample Usage:
# puppet apply -e "class { 'maestro::app::kits_db': }" --modulepath=/opt/config/production/git/maestro/puppet/modules:/etc/puppet/modules; --verbose

#
define maestro::app::run_ddl(
  $ddl_name             = $title,
  $mysql_server         = undef,
  $mysql_root_user      = undef,
  $mysql_root_password  = undef,
  $mysql_user           = undef,
  $mysql_password       = undef,
  $ddl_source           = undef,
  $ddl_content          = undef,
  $ddl_home_dir         = undef,
  $auth_provider        = hiera('maestro::auth_provider', 'launchpad'), # TODO: fix google
  $openidssourl         = hiera('maestro::openidssourl', 'https://login.launchpad.net/'), # TODO: fix https://www.google.com/accounts/o8/id
){

  if $mysql_server == undef
  {
    fail('missing mysql_server.')
  }
  if $mysql_root_user == undef
  {
    fail('missing mysql_root_user.')
  }
  if $mysql_root_password == undef
  {
    fail('missing mysql_root_password.')
  }
  if $mysql_user == undef
  {
    fail('missing mysql_user.')
  }
  if $mysql_password == undef
  {
    fail('missing mysql_password.')
  }
  if $ddl_home_dir == undef
  {
    fail('missing ddl_home_dir.')
  }
  if $ddl_source != undef
  {
    file { "${ddl_home_dir}/${ddl_name}":
      ensure => file,
      owner  => 'root',
      mode   => '0755',
      source => $ddl_source,
    }
  } elsif $ddl_content != undef
  {
    file { "${ddl_home_dir}/${ddl_name}":
      ensure  => file,
      owner   => 'root',
      mode    => '0755',
      content => template($ddl_content),
    }
  }

  exec { "run-ddl ${ddl_name}":
        command => "/usr/bin/mysql -h ${mysql_server} -u ${mysql_root_user} -p${mysql_root_password} < '${ddl_home_dir}/${ddl_name}'",
        require => [ File["${ddl_home_dir}/${ddl_name}"], Class['mysql_tuning'], ]
  }
}