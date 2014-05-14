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
  $app_dir     = undef,
  $revision    = hiera('maestro::ui::setup::revision','master'),
){
  require maestro::app::kits_db
  require maestro::requirements

  if $app_dir == undef
  {
    $app_dir_use = hiera('maestro::app::app_dir',"/opt/config/${::environment}/app")
  } else
  {
    $app_dir_use = $app_dir
  }

  if $revision == '' or $revision == undef
  {
    $vcs_revision = 'master'
    warning('Revision is not configured, defaulting to master.  Please set maestro::ui::setup::revision')
  } else
  {
    $vcs_revision = $revision
  }

  vcsrepo {"${app_dir_use}/maestro":
    ensure   => latest,
    provider => 'git',
    revision => $vcs_revision,
    source   => 'review:forj-oss/maestro',
    require  => [ Package['optimist'],
                  Package['restify'],
                  Package['path'],
                  Package['mysql'],
                  Package['js-yaml'],
                  Package['pm2'],
                  Package['sails'],
                ]
  } ->
  nodejs_wrap::pm2instance{'app.js':
    script_dir  => "${app_dir_use}/maestro/ui/",
    user        => $user,
  } ->
  nodejs_wrap::pm2instance{'bp-app.js':
      script_dir  => "${app_dir_use}/maestro/api/bp-api/",
      user        => $user,
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
  file { "${app_dir_use}/maestro/api/bp-api/config/config.json":
    ensure  => 'link',
    target  => "/opt/config/${::settings::environment}/config.json",
    owner   => $user,
    group   => $user,
  }
}