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
# This module execute mysql queries from a ddl script
#
# Parameters:
# $server:: An String, example localhost
# $user:: An String, example root
# $password:: An String with the password
# $ddl:: An String with sql ddl file
#
# Actions:
# (1) Connects to mysql and executes a script

# Sample Usage:
# puppet apply -e "class { 'maestro::app::kits_db': }" --modulepath=/opt/config/production/git/maestro/puppet/modules:/etc/puppet/modules; --verbose

#
class maestro::app::kits_db(
  $mysql_server         = hiera('maestro::app::mysql_server','localhost'),
  $mysql_root_user      = hiera('maestro::app::mysql_root_user','root'),
  $mysql_root_password  = hiera('maestro::app::mysql_root_password','changeme'),
  $mysql_user           = hiera('maestro::app::mysql_user','kitusr'),
  $mysql_password       = hiera('maestro::app::mysql_password','$Changeme01'),
  $ddl_home_dir         = undef,
){

  if $ddl_home_dir == undef
  {
    $ddl_home_dir_use = hiera('maestro::app::ddl_home_dir',"/opt/config/${::settings::environment}/app/ddl")
  } else
  {
    $ddl_home_dir_use = $ddl_home_dir
  }
  include mysql
  if !defined(Class['mysql::server'])
  {
    class { 'mysql::server':
      config_hash => { 'root_password' => $mysql_root_password }
    }
  }
  maestro::app::run_ddl{ 'kit_tools_ui.sql':
    mysql_server        => $mysql_server,
    mysql_root_user     => $mysql_root_user,
    mysql_root_password => $mysql_root_password,
    mysql_user          => $mysql_user,
    mysql_password      => $mysql_password,
    ddl_content         => 'maestro/app/ddl/kit_tools_ui.erb.sql',
    ddl_home_dir        => $ddl_home_dir_use,
  }
  maestro::app::run_ddl{ 'setup-db.sql':
    mysql_server        => $mysql_server,
    mysql_root_user     => $mysql_root_user,
    mysql_root_password => $mysql_root_password,
    mysql_user          => $mysql_user,
    mysql_password      => $mysql_password,
    ddl_content         => 'maestro/app/ddl/setup-db.erb.sql',
    ddl_home_dir        => $ddl_home_dir_use,
  }
  maestro::app::run_ddl{ 'forj.config-setup-db.sql':
    mysql_server        => $mysql_server,
    mysql_root_user     => $mysql_root_user,
    mysql_root_password => $mysql_root_password,
    mysql_user          => $mysql_user,
    mysql_password      => $mysql_password,
    ddl_content         => 'maestro/app/ddl/forj.config-setup-db.erb.sql',
    ddl_home_dir        => $ddl_home_dir_use,
  }
}
