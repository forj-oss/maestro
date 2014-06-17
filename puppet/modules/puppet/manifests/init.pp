#######################################################
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
# Puppet Client
# relies on a factor called altnodetype being defined on the puppetmaster with the value puppetmaster
# Configure puppet client
class puppet (
  $cron            = 'present',
  $graph           = 'present',
  $agent_timeout   = hiera('puppet::agent::timeout',800),
  $puppet_agentlog = hiera('puppet::agent::log','/var/log/puppet/puppetd.log'),
  # puppet.conf values
  $reports         = hiera('puppet::reports',undef),
  $reporturl       = hiera('puppet::reporturl',undef),
  $prerun_command  = hiera('puppet::prerun_command',''),
  $postrun_command = hiera('puppet::postrun_command',''),
  $puppetmaster    = hiera('puppet::puppetmaster','localhost'),
  $pluginsync      = hiera('puppet::pluginsync', true),
  $certname        = hiera('puppet::certname', $::fqdn),
  $manifestdir     = hiera('puppet::manifestdir', '/opt/config/$environment/puppet/manifests'),
  $manifest        = hiera('puppet::manifest', '$manifestdir/site.pp'),
  $modulepath      = hiera('puppet::modulepath', '/opt/config/$environment/puppet/modules:/etc/puppet/modules'),
  $splay           = hiera('puppet::splay', true),
  $splaylimit      = hiera('puppet::splaylimit', 30),
  $runinterval     = hiera('puppet::runinterval', 600),
  $listen          = hiera('puppet::listen', true),
  $storeconfigs    = hiera('puppet::storeconfigs', false),
  ) {


  $minute1=fqdn_rand(30)
  $minute2 = $minute1 + 30
  $minute3 = $minute1 + 15

  $timeout_cmd = "/usr/bin/timeout ${agent_timeout}"
  cron { 'puppet-agent':
    command     => "${timeout_cmd} /usr/bin/puppet agent --onetime --no-daemonize --logdest ${puppet_agentlog}",
    user        => 'root',
    minute      => [$minute1,$minute2],
    environment => [
        'FACTERLIB="/var/lib/puppet/lib/facter"',
        'PATH="/usr/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"'
    ],
  }

  cron { 'puppet-agent-graph':
    ensure   => $cron,
    command  => '/usr/local/bin/puppet-graph',
    user     => 'root',
    hour     => '2',
    minute   => $minute3,
  }

  if ($::osfamily == 'Debian') {
    file { '/etc/default/puppet':
      ensure  => $graph,
      content => template('puppet/default_puppet.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }

  # Running puppetd via cron instead of service due to memory locks
  service { 'puppet':
    ensure     => stopped,
    enable     => false,
    hasstatus  => true,
    hasrestart => true,
  }

  notice( "setting puppet.conf with '${modulepath}'")
  notice( "bp_modulepath ${::bp_modulepath}")
  notice( "extra_modulepath ${::extra_modulepath}")
  file { '/etc/puppet/puppet.conf':
    content => template('puppet/puppet.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    replace => true,
  }

  file { '/etc/puppet/etckeeper-commit-pre':
    source => 'puppet:///modules/puppet/etckeeper-commit-pre',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/puppet/etckeeper-commit-post':
    source => 'puppet:///modules/puppet/etckeeper-commit-post',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/puppet-cron':
    source => 'puppet:///modules/puppet/puppet-cron',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/puppet-graph':
    source => 'puppet:///modules/puppet/puppet-graph',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/logrotate.d/puppet':
    source => 'puppet:///modules/puppet/logrotate.d_puppet',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # make /var/lib/puppet readable for running facter -p as non-root
  file { '/var/lib/puppet':
    ensure  => directory,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '2755',
  }
} # end class puppet
