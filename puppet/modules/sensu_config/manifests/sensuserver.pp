# == Class: sensu_config::sensuserver
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
#
# Installs SensuServer
#

class sensu_config::sensuserver (
  $sensu_user     = hiera('sensu_config::sensuserver::sensu_user','sensu'),
  $sensu_vhost    = hiera('sensu_config::sensuserver::sensu_vhost','/sensu'),
  $subscriptions  = hiera('rabbit::subscriptions','sensu-test'),
  $rabbitmq_host  = hiera('rabbit::host','localhost'),
  $rabbitmq_port  = hiera('rabbit::port','5672'),
  $rabbit_admin   = hiera('rabbit::admin','admin'),
  $password       = hiera('rabbit::password'),
)
{
  require rabbit
  require maestro::redis::redisserver

  validate_string($sensu_user)
  validate_string($sensu_vhost)
  validate_string($subscriptions)
  validate_string($rabbitmq_host)
  validate_string($rabbit_admin)
  validate_string($password)

  if !is_integer($rabbitmq_port) { fail('sensu_config::sensuserver::rabbitmq_port must be an integer') }

  if $password == '' {
    fail('ERROR! rabbit::sensuserver::password is required.')
  }

  rabbitmq_vhost { $sensu_vhost:
    ensure  => present,
  }->
  rabbitmq_user { $sensu_user:
    ensure   => present,
    password => $password,
  }->
  rabbitmq_user_permissions { "${sensu_user}@${sensu_vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }->
  rabbitmq_user_permissions { "${rabbit_admin}@${sensu_vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }->
  class { 'sensu':
    server            => true,
    rabbitmq_password => $password,
    subscriptions     => $subscriptions,
    api               => true,
    rabbitmq_host     => $rabbitmq_host,
    rabbitmq_port     => $rabbitmq_port,
    rabbitmq_vhost    => $sensu_vhost,
  }

  sensu::check{ 'disk-metrics':
    command     => '/opt/sensu/embedded/bin/ruby /etc/sensu/plugins/disk-metrics.rb',
    subscribers => $subscriptions,
    interval    => '10',
    standalone  => false,
    type        => 'metric',
  }

  sensu::check{ 'cpu-metrics':
    command     => '/opt/sensu/embedded/bin/ruby /etc/sensu/plugins/cpu-metrics.rb',
    subscribers => $subscriptions,
    interval    => '10',
    standalone  => false,
    type        => 'metric',
  }

  sensu::check{ 'memory-metrics':
    command     => '/opt/sensu/embedded/bin/ruby /etc/sensu/plugins/memory-metrics.rb',
    subscribers => $subscriptions,
    interval    => '10',
    standalone  => false,
    type        => 'metric',
  }

  sensu::check{ 'check-disk':
    command     => '/opt/sensu/embedded/bin/ruby /etc/sensu/plugins/check-disk.rb -w 75 -c 85',
    subscribers => $subscriptions,
    interval    => '60',
    standalone  => false,
  }

  sensu::check{ 'check-cpu':
    command     => '/opt/sensu/embedded/bin/ruby /etc/sensu/plugins/check-cpu.rb',
    subscribers => $subscriptions,
    interval    => '60',
    standalone  => false,
  }

  sensu::check{ 'check-mem':
    command     => '/etc/sensu/plugins/check-mem.sh',
    subscribers => $subscriptions,
    interval    => '60',
    standalone  => false,
  }

}