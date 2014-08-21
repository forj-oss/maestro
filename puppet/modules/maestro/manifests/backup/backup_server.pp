# == Class: ::maestro::backup::backup_server
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

# This Puppet file describe what will be configured on Maestro for the backup system.

class maestro::backup::backup_server (
)
{
  include maestro::backup::params
  ## Prepares user
  $home = "${::maestro::backup::params::backup_home}/${::maestro::backup::params::backup_user}"
  user { $::maestro::backup::params::backup_user:
    ensure     => present,
    home       => $home,
    shell      => '/bin/bash',
    system     => true,
    managehome => true,
    comment    => 'User which keeps the kits backups boxes',
  }->
  file { $home:
    ensure => directory,
    owner  => $::maestro::backup::params::backup_user,
    mode   => '0755',
  }->
  file { "${home}/.ssh":
    ensure => directory,
    owner  => $::maestro::backup::params::backup_user,
    mode   => '0755',
  }->
  cacerts::sshgenkeys { $::maestro::backup::params::backup_user:
    do_cacertsdb => true,
  }

  #Install monitoring script

  file { "${maestro::backup::params::box_backup_path}/sbin":
    ensure  => directory,
    require => File [$maestro::backup::params::box_backup_path],
  }

  # Backup status management:
  file { "${maestro::backup::params::box_backup_path}/sbin/backup-status.py":
    ensure  => present,
    owner   => $::maestro::backup::params::backup_user,
    source  => 'puppet:///modules/maestro/backup/backup-status.py',
    mode    => '0555',
    require => File[$home],
  }
  # Ensure old corebkpadm is removed from the system.
  file { "${home}/corebkpadm":
    ensure  => absent,
  }

  cron { 'box_backupstatus':
    user    => $::maestro::backup::params::backup_user,
    hour    => '03',
    minute  => '30',
    command => "${maestro::backup::params::box_backup_path}/sbin/backup-status.py",
    require => File["${maestro::backup::params::box_backup_path}/sbin/backup-status.py"],
  }->
  notify{'Installed backup status script.':}

  # Restore script :
  file { "${maestro::backup::params::box_backup_path}/sbin/restoreraid.sh":
    ensure  => present,
    source  => 'puppet:///modules/maestro/backup/restoreraid.sh',
    mode    => '0555',
    require => File["${maestro::backup::params::box_backup_path}/sbin"],
  }


  ## Set connection Keys
  $ca_certs_db = '/opt/config/cacerts'
  $backup_public_key = cacerts_getkey(join( [ $ca_certs_db, '/ssh_keys/', "${::maestro::backup::params::backup_user}.pub" ]))
  if $backup_public_key != '' and $backup_public_key != undef
  {
    file { "${home}/.ssh/authorized_keys":
      ensure  => present,
      owner   => $::maestro::backup::params::backup_user,
      mode    => '0400',
      content => $backup_public_key,
      require => Cacerts::Sshgenkeys[$::maestro::backup::params::backup_user],
    }
  }
  ## Set backup folder
  file { $::maestro::backup::params::backup_fullpath:
    ensure  => directory,
    owner   => $::maestro::backup::params::backup_user,
    mode    => '0655',
    require => User[$::maestro::backup::params::backup_user],
  }->
  file { "${home}/backups":
    ensure => link,
    target => $::maestro::backup::params::backup_fullpath,
  }
  if ! defined(File['/etc/sudoers.d/forj-bck-sudoer'])
  {
    file { '/etc/sudoers.d/forj-bck-sudoer':
      ensure  => present,
      source  => 'puppet:///modules/maestro/backup/forj-bck-sudoer',
      owner   => 'root',
      group   => 'root',
      mode    => '0440',
      require => User[$::maestro::backup::params::backup_user],
    }
  }
}
