# == Class: ::maestro
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
# This class will be run on the maestro box as a part of the ui
# and agent setup
#

class maestro (
  $nodes            = hiera('maestro::nodes', undef),
  $ssh_user_keys    = hiera('maestro::ssh_user_keys', ['jenkins']),
  $instance_domain  = hiera('maestro::instance_domain', $domain),
  $instance_id      = hiera('maestro::instance_id', $::maestro_id),
  $image_name_arg   = hiera('maestro::image_name', 'Ubuntu Precise 12.04 LTS Server 64-bit 20121026 (b)'),
  $flavor_name_arg  = hiera('maestro::flavor_name', 'standard.xsmall'),
  $key_name_arg     = hiera('maestro::key_name', 'nova'),
  $network_name     = hiera('maestro::network_name', $::netname),
  $provision_set    = hiera('maestro::provision', $::provision),
  $security_groups  = hiera('maestro::security_goups', 'default'),
  $meta_data        = hiera('maestro::meta_data',''),
  $environment      = $settings::environment,
)
{
  # configure meta.js defaults
  if $flavor_name_arg == undef or $flavor_name_arg == ''
  {
    $flavor_name = 'standard.medium'
    warning('using hard value for flavor_name')
  }
  else
  {
    $flavor_name = $flavor_name_arg
  }

  if $image_name_arg == undef or $image_name_arg == ''
  {
    $image_name = 'proto2b'
    warning('using hard value for image_name')
  }
  else
  {
    $image_name = $image_name_arg
  }

  if $key_name_arg == undef or $key_name_arg == ''
  {
    $key_name = 'nova'
    warning('using hard value for key_name')
  }
  else
  {
    $key_name = $key_name_arg
  }
  # maestro is nothing without a puppet master,
  # make sure we execute the puppet master first!
  require puppet::puppetmaster

  # requirements
  include maestro::requirements

  # Install nodejs and pm2
  class {'nodejs_wrap':  }
  # we don't want this passed to us any other way.
  $env_dir          = hiera('maestro::app::app_dir',"/opt/config/${::environment}")
  $app_dir          = "${env_dir}/app"
  if $provision_set == '' or $provision_set == undef
  {
    $provision = true
  } else
  {
    $provision = $provision_set
  }
  Exec { path => [  '/bin/',
                    '/sbin/',
                    '/usr/bin/',
                    '/usr/sbin/',
                    '/usr/local/bin/'
                  ]
  }

  if ! defined(File["${env_dir}/blueprints"]) {
      file { "${env_dir}/blueprints" :
        ensure => directory,
        mode   => '0755',
      }
  }

  if ! defined(File["${env_dir}/puppet/modules"]) {
      file { "${env_dir}/puppet/modules" :
        ensure => directory,
        mode   => '0755',
      }
  }

  $ddl_home_dir = "${app_dir}/ddl"

  if ! defined(File[$app_dir]) {
      file { $app_dir :
        ensure => directory,
        mode   => '0755',
      }
  }
  if ! defined(File[$ddl_home_dir]) {
      file { $ddl_home_dir :
        ensure  => directory,
        mode    => '0755',
        require => File[$app_dir],
      }
  }

  include mysql_tuning
  include maestro::requirements
  include maestro::app::kits_db
  include maestro::app::setup
  include maestro::ui::setup
  include maestro::backup::backup_server
  include maestro::app::tool_status


  # Fog file may not be installed, and following code may fails. But maestro ui should be already installed and configured, anyway.
  debug("instance_id is ${instance_id}")
  $instance = $instance_id
  if ($provision == true) and ($::fog != 'UNDEF') and ($nodes != undef)
  {
    # create a server with non-default values
    class { 'maestro::orchestrator::setupallservers':
      environment    => $environment,
      nodes          => $nodes,
      instance       => $instance,
      ssh_gen_keys   => $ssh_user_keys,
      extra_metadata => $meta_data,
      require        => Class['puppet::puppetmaster'],
    }
  }

}
