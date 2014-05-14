# == Class: ::nodejs_wrap::pm2service
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
# Setup pm2service to work for nodejs apps

class nodejs_wrap::pm2service (
  $ensure      = hiera('nodejs_wrap::ensure', 'present'),
  $user        = hiera('nodejs_wrap::user', 'puppet'),
)
{
  require nodejs_wrap
  if $user == undef {
    fail('ERROR! nodejs_wrap::pm2service::user is undef')
  }
  if $ensure == 'present' {
      exec { 'install pm2 service':
        command => "pm2 startup ${::osfamily} -u ${user}",
        path    => $::path,
        require => Package['pm2'],
        onlyif  => "test $(stat -t /etc/rc?.d/S??pm2-init.sh > /dev/null 2<&1;echo $?) -gt 0"
      }
      #TODO: try to start pm2-init.sh after we find out what was wrong with the init.d script to start correctly.
      # for now we are leaving this disabled and relying on puppet to bring it back online.
      #service { 'pm2-init.sh':
      #  ensure  => 'running'
      #}
  }
}
