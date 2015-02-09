# Class: maestro::app::kits_db
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
# This module executes an import of key value pairs into Redis Database
#
# Parameters:
# $db_name:: Redis database name
# $ddl_home_dir:: Location to store the script
# $ddl_name:: File name of the redis script
# $keys:: Hiera hash containning key value pairs to store on redis
# $rootpw:: LDAP password, that will be stored on Redis Database
#
# Actions:
# (1) Connects to redis and executes a script
# Sample Usage:
# puppet apply -e "class { 'maestro::app::redis_db': }" --modulepath=/opt/config/production/git/maestro/puppet/modules:/etc/puppet/modules;
#
class maestro::app::redis_db(
  $db_name      = hiera('maestro::redis::db_name'),
  $ddl_home_dir = hiera('maestro::app::redis_db::ddl_home_dir',"/opt/config/${::settings::environment}/app/ddl"),
  $ddl_name     = hiera('maestro::app::redis_db::ddl_name','redis-db.txt'),
  $keys         = hiera_hash('maestro::app::redis_db::keys'),
  $rootpw       = hiera('ldap_config::rootpw'),
){
  validate_string($db_name)
  validate_absolute_path($ddl_home_dir)
  validate_string($ddl_name)
  validate_hash($keys)

  if ($rootpw == undef or $rootpw == '') {
    fail('ERROR! ldap_config::rootpw is required.')
  }

  if ($db_name == undef or $db_name == '') {
    fail('ERROR! maestro::redis::db_name is required.')
  }

  file { "${ddl_home_dir}/${ddl_name}":
    ensure  => file,
    owner   => 'root',
    mode    => '0755',
    content => template('maestro/app/ddl/redis-db.erb.txt'),
  }
  exec { "redis-massive-import ${ddl_name}":
        command => "/bin/cat ${ddl_home_dir}/${ddl_name} | /usr/bin/redis-cli --pipe",
        require => [ File["${ddl_home_dir}/${ddl_name}"], Class['maestro::redis::redisserver'], Class['ldap_config'], ]
  }
}
