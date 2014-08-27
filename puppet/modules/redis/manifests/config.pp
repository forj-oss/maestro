# == Class: redis::config
#
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

class redis::config {

  File {
    owner  => $::redis::config_owner,
    group  => $::redis::config_group,
    mode   => $::redis::config_file_mode,
    notify => Service[$::redis::service_name],
  }

  file {
    $::redis::config_dir:
      ensure => directory,
      mode   => $::redis::config_dir_mode;

    $::redis::config_file:
      ensure  => present,
      content => template($::redis::conf_template);

    $::redis::log_dir:
      ensure => directory,
      group  => $::redis::service_group,
      mode   => $::redis::config_dir_mode,
      owner  => $::redis::service_user;
  }
}
