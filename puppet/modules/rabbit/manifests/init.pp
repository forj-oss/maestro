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
  $admin         = hiera('rabbit::admin','admin'),
  $password      = hiera('rabbit::password'),
  $port          = hiera('rabbit::port','5672'),
  $vhost         = hiera('rabbit::vhost','maestro'),
  $exchange      = hiera('rabbit::exchange','maestro_exch'),
  $exchange_type = hiera('rabbit::exchange_type','topic'),
  $queues        = hiera('rabbit::queues','project user task backup'),
  $notif_queue   = hiera('rabbit::notif_queue','notification'),
  $notif_binding = hiera('rabbit::notif_queue','#.notification'),
  $durable       = hiera('rabbit::durable', true),
  $sh            = hiera('rabbit::sh', '/usr/lib/forj/rabbit_topology.sh'),
  $sh_user       = hiera('rabbit::sh_user','puppet'),
  $sh_group      = hiera('rabbit::sh_group','puppet'),
  $sh_mode       = hiera('rabbit::sh_mode','0755'),
)
{
  validate_string($admin)
  validate_string($password)
  validate_string($vhost)
  validate_string($exchange)
  validate_string($exchange_type)
  validate_string($queues)
  validate_bool($durable)
  validate_string($sh)
  validate_string($sh_user)
  validate_string($sh_group)
  validate_string($sh_mode)

  if !is_integer($port) { fail('rabbit::port must be an integer') }

  if $password == '' {
    fail('ERROR! rabbit::password is required.')
  }

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
  }->
  file { $sh:
    ensure  => 'present',
    content => template('rabbit/rabbit_topology.sh.erb'),
    owner   => $sh_user,
    group   => $sh_group,
    mode    => $sh_mode,
  }
  exec { 'rabbit_topology_exec':
    command => "${sh} '${admin}' '${password}'",
    path    => $::path,
    require => File[$sh],
  }
}