# == Class: ::maestro::backup::configure_box
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

class maestro::backup::configure_box (
  $uses_db = hiera('maestro::backup::configure_box::uses_db', false),
){
  if defined( Class['maestro::backup::backup_server'] ) {
    notify {'This is maestro, backup::configure_box skipped.':}
  }
  else {
    notify {'Not maestro, backup::configure_box configured.':}
    include maestro::backup::params
    include bup
    include apt

    package { 'rsync':
      ensure => present,
    }

    apt::source { 'ubuntu':
      location    => 'http://mirrors.kernel.org/ubuntu',
      repos       => 'main',
      include_src => false,
    }
    apt::source { 'percona':
      location    => 'http://repo.percona.com/apt',
      repos       => 'main',
      include_src => true,
      key         => '1C4CBDCDCD2EFD2A',
      key_server  => 'keys.gnupg.net',
    }
    package { 'percona-xtrabackup-21':
      ensure  => present,
      require => [ Apt::Source['ubuntu'], Apt::Source['percona'] ],
    }->
    notify {'xtrabackup installed.':}

    if !defined(File[$maestro::backup::params::box_backup_path])
    {
      file { $maestro::backup::params::box_backup_path :
        ensure  => directory,
        owner   => $maestro::backup::params::box_backup_user,
        mode    => '0755',
      }
    }

    file { "${maestro::backup::params::box_backup_path}/sbin" :
      ensure  => directory,
      owner   => $maestro::backup::params::box_backup_user,
      mode    => '0755',
      require => File [$maestro::backup::params::box_backup_path],
    }

    file { "${maestro::backup::params::box_backup_path}/sbin/runbkp":
      ensure  => present,
      source  => 'puppet:///modules/maestro/backup/runbkp',
      mode    => '0544',
      require => File["${maestro::backup::params::box_backup_path}/sbin"],
    }
    file { "${maestro::backup::params::box_backup_path}/sbin/restore.sh":
      ensure  => present,
      source  => 'puppet:///modules/maestro/backup/restore.sh',
      mode    => '0555',
      require => File["${maestro::backup::params::box_backup_path}/sbin"],
    }
    file { "${maestro::backup::params::box_backup_path}/sbin/master_bkp.sh":
      ensure  => present,
      source  => 'puppet:///modules/maestro/backup/master_bkp.sh',
      mode    => '0544',
      require => File["${maestro::backup::params::box_backup_path}/sbin"],
    }

    if $uses_db == 'yes' {
      #Database configuration file
      $db_user     = $maestro::backup::params::box_db_user
      $db_password = $maestro::backup::params::box_db_password
      $mysql_backup_init = template('maestro/backup/mysql_init.erb')
      $mysql_backup_check= "select count(*) from mysql.user where user='${db_user}'"
      exec { 'backup_mysql_init':
        path    => '/bin:/usr/bin',
        command => "mysql -e \"${mysql_backup_init}\" --verbose",
        onlyif  => "test $(mysql -N -B -e \"${mysql_backup_check}\") -eq 0",
      }->
      notify {'db backup configured.':}
    }
    else {
      notify {'NO db backup configured on this box.':}
    }

    if $maestro::backup::params::box_backup_user == 'root' {
      $home = '/root'
    }
    else {
      $home = "/home/${maestro::backup::params::box_backup_user}"
    }

    $ca_certs_db = '/opt/config/cacerts'
    $private_key = cacerts_getkey( join( [ $ca_certs_db, '/ssh_keys/', $maestro::backup::params::backup_user]))
    if $private_key != undef and $private_key != '' {
      file { "${home}/.ssh/${maestro::backup::params::backup_user}":
        ensure  => file,
        owner   => 'root',
        mode    => '0400',
        content => $private_key,
      }
      cacerts::add_ssh_host { $maestro::backup::params::backup_user :
        host_address  => $maestro::backup::params::box_backup_server,
        host_user     => $maestro::backup::params::backup_user,
        local_user    => $maestro::backup::params::box_backup_user,
        keyfile_name  => $maestro::backup::params::backup_user,
      }->
      notify {"${maestro::backup::params::backup_user} ssh configuration added.":}
    }
    else {
      notify {'WARNING, backup user private key was not found.':}
    }

    # Directories
    $etc_path=$maestro::backup::params::box_conf_folder
    $confd_path="${etc_path}/conf.d"
    $backup_path=$maestro::backup::params::box_backup_path
    $sbin_path="${backup_path}/sbin"
    $log_forj_path='/var/log/forj'

    file { $etc_path :
      ensure  => directory,
      owner   => $maestro::backup::params::box_backup_user,
      mode    => '0755',
    } ->
    file { $confd_path :
      ensure  => directory,
      owner   => $maestro::backup::params::box_backup_user,
      mode    => '0755',
    }


    file { $log_forj_path :
      ensure  => directory,
      owner   => $maestro::backup::params::box_backup_user,
      mode    => '0755',
    } ->
    cron { 'box_backup':
      user          => $maestro::backup::params::box_backup_user,
      hour          => '00',
      minute        => '20',
      command       => "${sbin_path}/master_bkp.sh --script ${sbin_path}/runbkp --configs ${confd_path}/*.conf >> ${log_forj_path}/backup_cron.log 2>&1",
      environment   => [  'PATH="/usr/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"'],
      require       => [  File["${sbin_path}/runbkp"],
                          File[$confd_path],
                          File["${sbin_path}/master_bkp.sh"] ],
    }->
    notify{'Installed box_backup cron job.':}
  }
}
