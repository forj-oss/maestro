# == Class: sensu_config::sensuclient
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
# Installs SensuClient
#

class sensu_config::sensuclient (
  $password       = hiera('rabbit::password'),
  $rabbitmq_host  = hiera('rabbit::host',$::eroip),
  $subscriptions  = hiera('rabbit::subscriptions','sensu-test'),
  $redis_host     = hiera('redis::params::host',$::eroip),
  $redis_port     = hiera('redis::params::port','6379'),
)
{
  validate_string($password)
  validate_string($rabbitmq_host)
  validate_string($subscriptions)
  validate_string($redis_host)

  if !is_integer($redis_port) { fail('sensu_config::sensuclient::redis_port must be an integer') }

  if $password == '' {
    fail('ERROR! rabbit::sensuclient::password is required.')
  }

  class { 'sensu':
    rabbitmq_password  => $password,
    rabbitmq_host      => $rabbitmq_host,
    redis_host         => $redis_host,
    redis_port         => $redis_port,
    subscriptions      => $subscriptions,
  }
}