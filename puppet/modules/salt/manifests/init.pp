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
# Class salt
#
class salt (
    $salt_master = hiera('salt::salt_master', "${::erosite}.${::erodomain}")
) {

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

    Apt::Ppa['ppa:saltstack/salt'] -> Package['salt-minion']

  }

  package { 'salt-minion':
    ensure  => present
  }

  file { '/etc/salt/minion':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('salt/minion.erb'),
    replace => true,
    require => Package['salt-minion'],
  }

  service { 'salt-minion':
    ensure    => running,
    enable    => true,
    require   => File['/etc/salt/minion'],
    subscribe => [
      Package['salt-minion'],
      File['/etc/salt/minion'],
    ],
  }
}
