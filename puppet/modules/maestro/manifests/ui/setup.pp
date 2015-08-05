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
  $user                  = hiera('maestro::ui::setup::user','puppet'),
  $app_dir               = hiera('maestro::app::app_dir',"/opt/config/${::environment}/app"),
  $revision              = hiera('maestro::ui::setup::revision','master'),

  # Repos
  $common_repo           = hiera('maestro::ui::setup::common_repo','https://review.forj.io/p/forj-oss/node-common'),
  $notifications_repo    = hiera('maestro::ui::setup::notifications_repo','https://review.forj.io/p/forj-oss/broker-notifications'),
  $projects_repo         = hiera('maestro::ui::setup::projects_repo','https://review.forj.io/p/forj-oss/broker-projects'),
  $maestro_repo          = hiera('maestro::ui::setup::maestro_repo','https://review.forj.io/p/forj-oss/maestro'),

  # Project Names
  $common                = hiera('maestro::ui::setup::common','node-common'),
  $notifications         = hiera('maestro::ui::setup::notifications','broker-notifications'),
  $projects              = hiera('maestro::ui::setup::projects','broker-projects'),
  $maestro               = hiera('maestro::ui::setup::maestro','maestro'),

  # Npm modules from node-common project
  $msg_util              = hiera('maestro::ui::setup::msg_util','msg-util'),
  $queue_util            = hiera('maestro::ui::setup::queue_util','queue-util'),
  $crypto_util           = hiera('maestro::ui::setup::crypto_util','crypto-util'),
  $project_util          = hiera('maestro::ui::setup::project_util','project-util'),

  # Applications Js app
  $maestro_api_js        = hiera('maestro::ui::setup::maestro_api_js','maestro-api.js'),
  $maestro_js            = hiera('maestro::ui::setup::maestro_js','maestro-app.js'),
  $bp_api_js             = hiera('maestro::ui::setup::bp_api_js','bp-app.js'),
  $projects_js           = hiera('maestro::ui::setup::projects_js','projects-broker.js'),
  $notifications_js      = hiera('maestro::ui::setup::maestro_api_js','user-notifcation-broker.js'),

  # Applications path starting from $app_dir
  $maestro_api_dir       = hiera('maestro::ui::setup::maestro_api_dir','maestro/api/maestro-api'),
  $maestro_dir           = hiera('maestro::ui::setup::maestro_dir','maestro/ui'),
  $bp_api_dir            = hiera('maestro::ui::setup::bp_api_dir','maestro/api/bp-api'),
  $projects_dir          = hiera('maestro::ui::setup::projects_dir','broker-projects/projects-broker'),
  $notifications_dir     = hiera('maestro::ui::setup::notifications_dir','broker-notifications/user-notifications'),

  # password to use in the file connections.js
  $mysql_kitusr_password = hiera('mysql_kitusr_password'),
){
  require maestro::app::kits_db
  require maestro::requirements

  validate_string($user)
  validate_string($app_dir)
  validate_string($revision)
  validate_string($mysql_kitusr_password)

  # forj-oss/node-common
  vcsrepo {"${app_dir}/${common}":
    ensure   => present,
    provider => 'git',
    revision => $revision,
    source   => $common_repo,
    require  => [ Package['pm2'],
                  Package['sails'],
                ]
  } ->
  exec { "npm install of ${msg_util}":
    command => 'npm install',
    path    => $::path,
    cwd     => "${app_dir}/${common}/${msg_util}",
  } ->
  exec { "npm install of ${queue_util}":
    command => 'npm install',
    path    => $::path,
    cwd     => "${app_dir}/${common}/${queue_util}",
  } ->
  exec { "npm install of ${crypto_util}":
    command => 'npm install',
    path    => $::path,
    cwd     => "${app_dir}/${common}/${crypto_util}",
  } ->
  exec { "npm install of ${project_util}":
    command => 'npm install',
    path    => $::path,
    cwd     => "${app_dir}/${common}/${project_util}",
  } ->

  # forj-oss/notifications-broker
  vcsrepo {"${app_dir}/${notifications}":
    ensure   => present,
    provider => 'git',
    revision => $revision,
    source   => $notifications_repo,
  } ->
  file { "${app_dir}/${notifications_dir}/node_modules/${msg_util}":
    ensure => 'link',
    target => "${app_dir}/${common}/${msg_util}",
    owner  => $user,
    group  => $user,
  } ->

  # forj-oss/broker-projects
  vcsrepo {"${app_dir}/${projects}":
    ensure   => present,
    provider => 'git',
    revision => $revision,
    source   => $projects_repo,
  } ->
  file { "${app_dir}/${projects_dir}/node_modules/${queue_util}":
    ensure => 'link',
    target => "${app_dir}/${common}/${queue_util}",
    owner  => $user,
    group  => $user,
  } ->
  file { "${app_dir}/${projects_dir}/node_modules/${msg_util}":
    ensure => 'link',
    target => "${app_dir}/${common}/${msg_util}",
    owner  => $user,
    group  => $user,
  } ->

  # forj-oss/maestro
  vcsrepo {"${app_dir}/${maestro}":
    ensure   => present,
    provider => 'git',
    revision => $revision,
    source   => $maestro_repo,
  } ->
  file { "${app_dir}/${maestro_dir}/node_modules/${queue_util}":
    ensure => 'link',
    target => "${app_dir}/${common}/${queue_util}",
    owner  => $user,
    group  => $user,
  } ->
  file { "${app_dir}/${maestro_dir}/node_modules/${msg_util}":
    ensure => 'link',
    target => "${app_dir}/${common}/${msg_util}",
    owner  => $user,
    group  => $user,
  } ->
  file { "${app_dir}/${maestro_dir}/node_modules/${crypto_util}":
    ensure => 'link',
    target => "${app_dir}/${common}/${crypto_util}",
    owner  => $user,
    group  => $user,
  } ->
  file { "${app_dir}/${maestro_dir}/node_modules/${project_util}":
    ensure => 'link',
    target => "${app_dir}/${common}/${project_util}",
    owner  => $user,
    group  => $user,
  } ->
  file { "${app_dir}/${bp_api_dir}/config/config.json":
    ensure => 'link',
    target => "/opt/config/${::settings::environment}/config.json",
    owner  => $user,
    group  => $user,
  } ->

  # creates the file connections.js with the dynamically assigned password in it
  file { "/opt/config/production/git/${bp_api_dir}/config/connections.js":
    ensure  => present,
    owner   => $user,
    group   => $user,
    mode    => '0660',
    content => template('maestro/ui/connections_js.erb'),
  } ->
  nodejs_wrap::pm2instance{$maestro_api_js:
    script_dir => "${app_dir}/${maestro_api_dir}",
    user       => $user,
  } ->
  nodejs_wrap::pm2instance{$bp_api_js:
      script_dir => "${app_dir}/${bp_api_dir}",
      user       => $user,
  } ->
  nodejs_wrap::pm2instance{$projects_js:
      script_dir => "${app_dir}/${projects_dir}",
      user       => $user,
  } ->
  nodejs_wrap::pm2instance{$notifications_js:
      script_dir => "${app_dir}/${notifications_dir}",
      user       => $user,
  } ->
  nodejs_wrap::pm2instance{$maestro_js:
    script_dir => "${app_dir}/${maestro_dir}",
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
  }
}
