# == Class: ::maestro::backup::cdn_upload
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

# This Puppet manifests uploads the backup files from maestro to object storage

class maestro::backup::cdn_upload (
)
{
  include maestro::backup::params

  validate_string($maestro::backup::params::backup_fullpath)
  validate_string($maestro::backup::params::maestro_tar_file)
  validate_string($::domain)

  # TODO Append date of creation to backup.tar, example backup-04-30-14.tar
  # TODO Cleanup manifests to delete backups older than x days in the cloud storage and locally (maestro box)
  exec {'tar-mnt-backups':
    cwd     => $maestro::backup::params::backup_fullpath,
    command => "/bin/tar cvf ${maestro::backup::params::maestro_tar_file} ${maestro::backup::params::backup_fullpath}/*",
    onlyif  => "/usr/bin/test -e ${maestro::backup::params::backup_fullpath}"
  }->
  pinascdn {'backup-delete':
    ensure     => absent,
    file_name  => $maestro::backup::params::maestro_tar_file,
    remote_dir => $::domain,
    local_dir  => $maestro::backup::params::backup_fullpath,
  }->
  pinascdn {'backup-upload':
    ensure     => present,
    file_name  => $maestro::backup::params::maestro_tar_file,
    remote_dir => $::domain,
    local_dir  => $maestro::backup::params::backup_fullpath,
  }
}
