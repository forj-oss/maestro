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
# Class salt::master
#
class salt::master (
  $salt_reactor_jobs = hiera_array('salt::salt_reactor',undef)
){

  if ($::osfamily == 'Debian') {
    include apt

    # Wrap in ! defined checks to allow minion and master installs on the
    # same host.
    if ! defined(Apt::Ppa['ppa:saltstack/salt']) {
      apt::ppa { 'ppa:saltstack/salt': }
    }

    if ! defined(Package['python-software-properties']) {
      package { 'python-software-properties':
        ensure => present,
      }
    }

    Apt::Ppa['ppa:saltstack/salt'] -> Package['salt-master']

  }

  package { 'salt-master':
    ensure  => present
  }

  group { 'salt':
    ensure => present,
    system => true,
  }

  user { 'salt':
    ensure  => present,
    gid     => 'salt',
    home    => '/home/salt',
    shell   => '/bin/bash',
    system  => true,
    require => Group['salt'],
  }

  file { '/home/salt':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0755',
    require => User['salt'],
  }

# uses $salt_reactor_jobs for nodes of script reactor scripts to run
  file { '/etc/salt/master':
    ensure  => present,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0644',
    content => template('salt/master.yaml.erb'),
    replace => true,
    require => Package['salt-master'],
  }

  file { '/srv/reactor':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0755',
    require => [
      Package['salt-master'],
      User['salt'],
    ],
  }

  file { '/srv/salt':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/mnt/salt':
    ensure => directory,
    owner  => 'salt',
    group  => 'salt',
    mode   => '0765',
  }


  file { '/srv/salt/_modules':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [
      File['/srv/salt'],
    ],
  }

  file { '/srv/salt/_modules/change_mysql_password.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('salt/change_mysql_password.py'),
    replace => true,
    require => [
      File['/srv/salt/_modules'],
    ],
  }

  file { '/etc/salt/pki':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0710',
    require => [
      Package['salt-master'],
      User['salt'],
    ],
  }

  file { '/etc/salt/pki/master':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0770',
    require => File['/etc/salt/pki'],
  }

  file { '/etc/salt/pki/master/minions':
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0775',
    require => File['/etc/salt/pki/master'],
  }

  class {'salt::salt_reactor':
    require => [
      Package['salt-master'],
      File['/srv/reactor'],
    ]
  }

  file { '/var/run/salt' :
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0755',
    require => [
      Package['salt-master'],
      User['salt'],
    ],
  }

  file { '/var/run/salt/master' :
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0755',
    require => [
      File['/var/run/salt']
    ],
  }

  file { '/var/run/salt/minion' :
    ensure  => directory,
    owner   => 'salt',
    group   => 'salt',
    mode    => '0755',
    require => [
      File['/var/run/salt']
    ],
  }

  service { 'salt-master':
    ensure    => running,
    enable    => true,
    require   => [
      User['salt'],
      File['/etc/salt/master'],
    ],
    subscribe => [
      Package['salt-master'],
      File['/etc/salt/master'],
    ],
  }

  exec {'register-minions':
    command   => 'salt-key --accept-all --yes',
    require   => Service['salt-master'],
    onlyif    => ["test $(salt-key --list=pre | grep ${::erodomain} | grep -v 'Unaccepted Keys:' | wc -l) -gt 0"],
    path      => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    logoutput => true,
  }

  if ! defined(File['/etc/sudoers.d/salt-sudoer'])
  {
    file { '/etc/sudoers.d/salt-sudoer':
      ensure => present,
      source => 'puppet:///modules/salt/salt-sudoer',
      owner  => 'root',
      group  => 'root',
      mode   => '0440',
    }
  }

}
