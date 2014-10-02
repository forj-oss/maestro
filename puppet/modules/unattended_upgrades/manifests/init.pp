# == Class: unattended_upgrades
#
# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
#
class unattended_upgrades(
  $ensure = present,
  $origins = []
) {
  package { 'unattended-upgrades':
    ensure => $ensure,
  }

  package { 'mailutils':
    ensure => $ensure,
  }

  file { '/etc/apt/apt.conf.d/10periodic':
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/unattended_upgrades/10periodic',
    replace => true,
  }

  file { '/etc/apt/apt.conf.d/50unattended-upgrades':
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('unattended_upgrades/50unattended-upgrades.erb'),
    replace => true,
  }
}
