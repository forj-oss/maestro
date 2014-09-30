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
include 'erlang'

#
# Installs RabbitMQ
#
class rabbit (
  $admin    = hiera('rabbit::admin','admin'),
  $password = hiera('rabbit::password'),
)
{
  class { 'rabbitmq':
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
  }
}
