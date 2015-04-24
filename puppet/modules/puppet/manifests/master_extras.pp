# == Class: ::puppetmaster
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
# puppet master module
# TODO: this module should be contributed back to replace openstack_project:puppetmaster
# set $keep_puppetmaster_updated = false to disable git update/reset

class puppet::master_extras (
  $keep_puppetmaster_updated = true,
) {

  # imunity orchestration
  class { 'salt::master': }

  case $keep_puppetmaster_updated {
    true:    { $updatepuppetcmd = 'present' }
    false:   { $updatepuppetcmd = 'absent' }
    default: { fail('invalid value for $keep_puppetmaster_updated')}
  }

  cron { 'updatepuppetmaster':
    ensure      => $updatepuppetcmd,
    user        => 'root',
    minute      => '*/15',
    command     => 'sleep $((RANDOM\%600)) && cd /opt/config/production/git/config && git fetch -q && git reset -q --hard @{u} && ./install_modules.sh',
    environment => 'PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

# Cloud credentials are stored in this directory for launch-node.py.
  file { '/root/ci-launch':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
    }

# For launch/launch-node.py.
# insure python is installed

  include pip::python2
  $pip_provider = pip2
  if(!defined(Package['python-cinderclient']))
  {
    package { 'python-cinderclient':
      ensure   => latest,
      provider => $pip_provider,
    }
  }

  if(!defined(Package['python-novaclient']))
  {
    package { 'python-novaclient':
      ensure   => latest,
      provider => $pip_provider,
    }
  }

  if(!defined(Package['python-paramiko']))
  {
    package { 'python-paramiko':
      ensure => present,
    }
  }
}
