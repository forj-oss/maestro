# == Class: sensu_config::uchiwa
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
# Installs Uchiwa Dashboard
#

class sensu_config::uchiwa (
  $app_dir         = hiera('sensu_config::uchiwa::app_dir',"/opt/config/${::environment}/app/uchiwa"),
  $revision        = hiera('sensu_config::uchiwa::revision','master'),
  $fqdn            = hiera('sensu_config::uchiwa::fqdn',$::fqdn),
  $sensu_api_port  = hiera('sensu_config::uchiwa::sensu_api_port',4567),
  $uchiwa_port     = hiera('sensu_config::uchiwa::uchiwa_port',3010),
  $uchiwa_user     = hiera('sensu_config::uchiwa::uchiwa_user','sensu'),
  $uchiwa_password = hiera('sensu_config::uchiwa::uchiwa_password','changeme'),
)
{
  require rabbit
  require maestro::redis::redisserver
  require sensu_config::sensuserver

  validate_string($app_dir)
  validate_string($revision)
  validate_string($fqdn)
  validate_string($sensu_api_port)
  validate_string($uchiwa_port)
  validate_string($uchiwa_user)
  validate_string($uchiwa_password)

  vcsrepo {$app_dir:
    ensure   => latest,
    provider => 'git',
    revision => $revision,
    source   => 'https://github.com/miqui/uchiwa.git',
    require  => [ Package['pm2'],
                  Package['sails'],
                ]
  }
  file { "${app_dir}/config.json":
      ensure  => file,
      content => template('sensu_config/uchiwa/config.json.erb'),
      require => Vcsrepo[$app_dir],
  }
  nodejs_wrap::pm2instance{'uchiwa.js':
    script_dir => $app_dir,
    require    => File["${app_dir}/config.json"],
  }
  exec { 'uchiwa-npm-run-postinstall':
    command     => 'npm run postinstall',
    path        => $::path,
    cwd         => $app_dir,
    require     => Exec['npm install of uchiwa.js'],
    creates     => "${app_dir}/public/bower_components",
  }
}