# == Class: rabbit
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

# this sets up the repository and installs the erlang package.
case $operatingsystem {
      'RedHat', 'CentOS': { include 'erlang'
                            class { 'erlang': epel_enable => true }
                          }
      /^(Debian|Ubuntu)$/:{ include 'erlang'
                            package { 'erlang-base': ensure => 'latest', }
                          }
      default:            { fail("Unsupported ${::operatingsystem}") }
}

#
# Installs RabbitMQ
#
class rabbit (
  $admin    = hiera('rabbit::admin','admin'),
  $password = hiera('rabbit::password'),
  $port     = hiera('rabbit::port','5672'),
  $vhost    = hiera('rabbit::maestro_vhost','/maestro')
)
{
  class { 'rabbitmq':
    port              => $port,
    delete_guest_user => true,
  }->
  rabbitmq_user { $admin:
    ensure   => present,
    admin    => true,
    password => $password,
  }->
  rabbitmq_user_permissions { "${admin}@/":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }->
  rabbitmq_vhost { $vhost:
    ensure  => present,
  }->
  rabbitmq_user_permissions { "${admin}@${vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }
}
