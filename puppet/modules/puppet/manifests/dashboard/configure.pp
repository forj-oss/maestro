# installs puppet dashboard
#
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
class puppet::dashboard::configure(
    $password = hiera('puppet::dashboard::password','changeme'),
    $mysql_root_password = hiera('mysql_root_password'),
) {

  validate_string($mysql_root_password)

  if ! defined(Package['ruby1.9.3'])  {
    package { 'ruby1.9.3':
              ensure => 'present',
            }
  }

  if ! defined(Alternatvies['ruby'])
  {
    alternatives { 'ruby':
      path    => '/usr/bin/ruby1.9.1',
      require => Package['ruby1.9.3'],
    }
  }


  if ! defined(Alternatvies['gem'])
  {
    alternatives { 'gem':
      path    => '/usr/bin/gem1.9.1',
      require => Alternatives['ruby'],
    }
  }

  class { '::dashboard':
    dashboard_ensure   => 'present',
    dashboard_user     => 'www-data',
    dashboard_group    => 'www-data',
    dashboard_password => $password,
    dashboard_db       => 'dashboard_prod',
    dashboard_charset  => 'utf8',
    dashboard_site     => $::fqdn,
    dashboard_port     => '3000',
    mysql_root_pw      => $mysql_root_password,
    passenger          => true,
    require            => Package['ruby1.9.3'],
  }

  file { '/etc/mysql/conf.d/mysqld_innodb_fpt.cnf':
    ensure  => present,
    source  =>
      'puppet:///modules/puppet/dashboard/mysqld_innodb_fpt.cnf',
    require => Class['mysql::server'],
  }

  file { '/etc/default/puppet-dashboard-workers':
    ensure  => present,
    content => "START=yes\nNUM_DELAYED_JOB_WORKERS=2",

    require => Class['::dashboard'],
  }

  service { 'puppet-dashboard-workers':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/default/puppet-dashboard-workers'],
  }
  # Installation of Phusion Passenger module
  if !defined(Package['libapache2-mod-passenger'])
  {
    package { 'libapache2-mod-passenger':
      ensure    => 'installed',
      subscribe => Service['apache2'],
    }
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
