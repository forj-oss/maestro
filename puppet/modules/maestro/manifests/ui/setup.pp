# Class: maestro::ui::setup
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
# This module installs forj-oss/maestro
#
# Parameters:
# $dir:: An String specifying path to clone maestro
#
# Actions:
# (1) Requires nodejs
# (2) uses npm to install required nodejs packages
# (3) starts maestro ui

# Sample Usage:
# puppet apply -e "class { 'maestro::ui::setup': }" --modulepath=/opt/config/production/git/redstone/puppet/modules:/etc/puppet/modules; --verbose


class maestro::ui::setup(
  $user        = hiera('maestro::ui::setup::user','puppet'),
  $app_dir     = hiera('maestro::app::app_dir',"/opt/config/${::environment}/app"),
  $revision    = hiera('maestro::ui::setup::revision','master'),
){
  require maestro::app::kits_db
  require maestro::requirements

  validate_string($user)
  validate_string($app_dir)
  validate_string($revision)

  vcsrepo {"${app_dir}/node-common":
    ensure   => latest,
    provider => 'git',
    revision => $revision,
    source   => 'https://review.forj.io/p/forj-oss/node-common',
  } ->
  vcsrepo {"${app_dir}/maestro":
    ensure   => latest,
    provider => 'git',
    revision => $revision,
    source   => 'https://review.forj.io/p/forj-oss/maestro',
    require  => [ Package['JSONPath'],
                  Package['optimist'],
                  Package['bunyan'],
                  Package['restify'],
                  Package['path'],
                  Package['mysql'],
                  Package['js-yaml'],
                  Package['pm2'],
                  Package['sails'],
                ]
  } ->
  nodejs_wrap::pm2instance{'app.js':
    script_dir => "${app_dir}/maestro/ui/",
    user       => $user,
  } ->
  nodejs_wrap::pm2instance{'maestro-api.js':
    script_dir => "${app_dir}/maestro/api/maestro-api/",
    user       => $user,
  } ->
  nodejs_wrap::pm2instance{'bp-app.js':
      script_dir => "${app_dir}/maestro/api/bp-api/",
      user       => $user,
  } ->
  a2mod { ['proxy_http','proxy']:
    ensure  => present,
  } ->
  apache::vhost { 'maestro':
        port       => 80,
        docroot    => 'MEANINGLESS ARGUMENT',
        priority   => '70',
        template   => 'maestro/maestro_vhost.erb',
        servername => 'localhost',
  } ->
  file { "${app_dir}/maestro/api/bp-api/config/config.json":
    ensure => 'link',
    target => "/opt/config/${::settings::environment}/config.json",
    owner  => $user,
    group  => $user,
  } ->
  file { "${app_dir}/maestro/ui/node_modules/queue-util":
    ensure => 'link',
    target => "${app_dir}/node-common/queue-util",
    owner  => $user,
    group  => $user,
  } ->
  file { "${app_dir}/maestro/ui/node_modules/msg-util":
    ensure => 'link',
    target => "${app_dir}/node-common/queue-util",
    owner  => $user,
    group  => $user,
  }
}
