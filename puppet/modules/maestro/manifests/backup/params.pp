# Class: maestro::backup::params
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
# manage backup parameters

class maestro::backup::params (
  $backup_user            = hiera('maestro::backup::backup_user'           , 'forj-bck'),
  $backup_home            = hiera('maestro::backup::backup_home'           , '/home'),
  $backup_fullpath        = hiera('maestro::backup::backup_fullpath'       , '/mnt/backups'),
  $box_backup_path        = hiera('maestro::backup::box_backup_path'       , '/usr/lib/forj'),
  $box_conf_folder        = hiera('maestro::backup::box_backup_etc_path'   , '/etc/forj'),
  $box_backup_user        = hiera('maestro::backup::box_backup_user'       , 'root'),
  $maestro_backup_server  = hiera('maestro::backup::maestro_backup_server' , ''),
  $maestro_tar_file       = hiera('maestro::backup::maestro_tar_file'      , 'backups.tar'),
  $logrotate_name         = hiera('maestro::backup::params::logrotate_name', 'runbck'),
  $logrotate_path         = hiera('maestro::backup::logrotate_path'        , '/var/log/forj/backup_cron.log'),
  $logrotate_rotate       = hiera('maestro::backup::logrotate_rotate'      , 2),
  $logrotate_size         = hiera('maestro::backup::logrotate_size'        , '1G'),
  $logrotate_create_mode  = hiera('maestro::backup::logrotate_create_mode' , '0644'),
  $logrotate_create_owner = hiera('maestro::backup::logrotate_create_owner', 'root'),
  $logrotate_create_group = hiera('maestro::backup::logrotate_create_group', 'root'),
  $logrotate_rotate_every = hiera('maestro::backup::logrotate_rotate_every', 'monthly'),
  $number_of_backups_to_retain = hiera('maestro::backup::number_of_backups_to_retain', 4),
) {
}
