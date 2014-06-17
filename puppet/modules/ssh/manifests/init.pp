# == Class: ssh
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
class ssh {
    include ssh::params
    package { $::ssh::params::package_name:
      ensure => present,
    }
    service { $::ssh::params::service_name:
      ensure     => running,
      hasrestart => true,
      subscribe  => File['/etc/ssh/sshd_config'],
    }
    file { '/etc/ssh/sshd_config':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => [
        "puppet:///modules/ssh/sshd_config.${::osfamily}",
        'puppet:///modules/ssh/sshd_config',
      ],
      replace => true,
    }
}
