# == Class: snmpd
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
class snmpd {

  include snmpd::params

  package { 'snmpd':
    ensure => present,
    name   => $::snmpd::params::package_name,
  }
  service { 'snmpd':
    ensure     => running,
    hasrestart => true,
    require    => File['/etc/snmp/snmpd.conf']
  }

  if ($::osfamily == 'Debian') {
    # This file is only needed on machines pre-precise. There is a bug in
    # the previous init script versions which causes them to attempt
    # snmptrapd even if it's configured not to run, and then to report
    # failure.
    file { '/etc/init.d/snmpd':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/snmpd/snmpd.init',
      replace => true,
      require => Package['snmpd'],
    }

    File['/etc/init.d/snmpd'] -> Service['snmpd']

  }

  file { '/etc/snmp/snmpd.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/snmpd/snmpd.conf',
    replace => true,
  }
}
