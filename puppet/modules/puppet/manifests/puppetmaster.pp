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
#######################################################
# Puppetmaser

class puppet::puppetmaster
(
  $vhost_name        = hiera('puppet::puppetmaster::vhost_name', 'puppetmaster'),
  $vhost_priority    = hiera('puppet::puppetmaster::vhost_priority', '80'),
  $vhost_template    = hiera('puppet::puppetmaster::vhost_template','puppet/puppetmaster.vhost.erb'),
  $certname          = hiera('puppet::puppetmaster::certname', $::fqdn),
  $config_root       = hiera('puppet::config_home', '/opt/config'),
  $puppetmaster_port = '8140', # TODO: need to test if changing the port really works, if so we should hiera it.
) {

  if ($::osfamily == 'Debian') {
    $puppet_lib_dir = '/var/lib/puppet'
    $puppet_ssl_dir = "${puppet_lib_dir}/ssl"
    file { $puppet_ssl_dir:
      ensure  => directory,
      owner   => puppet,
      group   => puppet,
      mode    => '0771',
      require => Package['puppet-common'],
    } ->

    file { "${puppet_ssl_dir}/ca":
      ensure  => directory,
      owner   => puppet,
      group   => puppet,
      mode    => '0770',
      require => Package['puppet-common'],
    } ->

    file { "${puppet_ssl_dir}/ca/signed":
      ensure  => directory,
      owner   => puppet,
      group   => puppet,
      mode    => '0770',
      require => Package['puppet-common'],
    } ->

    file { "${puppet_lib_dir}/reports":
      ensure  => directory,
      owner   => puppet,
      group   => puppet,
      mode    => '0750',
    } ->

    file { '/etc/default/puppetmaster':
      ensure  => 'present',
      content => template('puppet/default_puppetmaster.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    } ->

    file { '/etc/apache2/sites-enabled/puppetmaster':
      ensure => 'absent',
    } ->

    file { '/etc/apache2/sites-available/puppetmaster':
      ensure => 'absent',
    }

    if ! defined(File[$config_root])
    {
      file { $config_root:
        ensure  => directory,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '2755',
        require => File['/etc/apache2/sites-available/puppetmaster'],
      }
    }

    if ! defined(File["${config_root}/${settings::environment}"])
    {
      file { "${config_root}/${settings::environment}":
        ensure  => directory,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '2755',
        require => File[$config_root],
      }
    }

    apache::vhost { $vhost_name:
      port     => 443,
      docroot  => 'MEANINGLESS ARGUMENT',
      priority => $vhost_priority,
      template => $vhost_template,
      ssl      => true,
      require  => [ Package['puppetmaster'],
                    Package['puppetmaster-common'],
                    Package['puppetmaster-passenger']
                  ],
    }
  }

  # Running puppetmaster via passenger
  service { 'puppetmaster':
    ensure     => stopped,
    enable     => false,
    hasstatus  => true,
    hasrestart => true,
    require    => [ Package['puppetmaster'],
                    Package['puppetmaster-common'],
                  ],
    before     => Package['puppetmaster-passenger']
  }


}
