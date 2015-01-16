# == Class: ::maestro::backup::clean_backups
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

#    This Puppet manifest cleans up old backups from maestro before sending to
#    the 'cdn_upload.pp' manifest.
class maestro::backup::clean_backups (
  $nodes = hiera('maestro::nodes', []),
)
{
  include maestro::backup::params

  $sbin_path="${maestro::backup::params::box_backup_path}/sbin"

  file { "${sbin_path}/cleanbkps.sh":
    ensure  => present,
    content => template('maestro/backup/cleanbkps.sh.erb'),
    mode    => '0544',
    require => File[$sbin_path],
  }

  exec { 'cleanup-backups':
    require => File["${sbin_path}/cleanbkps.sh"],
    cwd     => $maestro::backup::params::backup_fullpath,
    command => "${sbin_path}/cleanbkps.sh ${maestro::backup::params::number_of_backups_to_retain}",
  }
}
