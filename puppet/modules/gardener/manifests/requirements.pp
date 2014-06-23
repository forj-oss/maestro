# == gardener::requirements
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
# check that fog api is installed as a gem and that we can use it.
# check for json
#
#

class gardener::requirements {

# this option for installing fog simply isn't availabe because of bugs
# with gem installation with multiple rubys installed, package defaults
# to system ruby installed, and puppet on 2.7.X Ubuntu only works with
# ruby 1.8....which is a slight issue for fog due to nokogiri 1.6.X
#      package { 'fog':
#        ensure => present,
#        provider => gem
#      } ->
  tag 'gardener::requirements'
  $package_data = parseyaml("
  make:
    ensure: 'latest'
    require: 'Package[libxslt-dev]'
  mime-types:
    ensure: '1.25.1'
    provider: 'gem18'
    require: 'Package[make]'
  excon:
    ensure: '0.31.0'
    provider: 'gem18'
    require: 'Package[mime-types]'
  json:
    ensure: 'latest'
    provider: 'gem18'
    require: 'Package[excon]'
  nokogiri:
    ensure: '1.5.11'
    provider: 'gem18'
    require: 'Package[json]'
  fog:
    ensure: '1.19.0'
    provider: 'gem18'
    require: 'Package[nokogiri]'
  dos2unix:
    ensure: 'latest'
  libxslt-dev:
    ensure: 'latest'
")
  $packages = keys($package_data)

  gardener::requirements_package { $packages:
      data => $package_data,
  }

  # custom installation for hpcloud from gem file for private cloud implementation support.
  # currently forked on github at wenlock/unix_cli
  $unix_cli_version='2.0.8'
  $unix_cli_name='hpcloud'
  $unix_cli_md5='93fc19d1afdcd37a5962b28b5517f94f'
  $unix_cli_url='http://nexus.cdkdev.org:8080/nexus/content/repositories/cdk-content/io/forj/cli/hpcloud'
  if ! defined(File['/var/lib/forj']) {
    file { '/var/lib/forj' :
      ensure => directory,
      mode   => '0755',
    }
  }
  downloader {"${unix_cli_url}/${unix_cli_version}/hpcloud-${unix_cli_version}.gem":
            ensure          => present,
            path            => "/var/lib/forj/${unix_cli_version}-${unix_cli_version}.gem",
            md5             => $unix_cli_md5,
            owner           => 'puppet',
            group           => 'puppet',
            mode            => 755,
            replace         => false,
            provider        => url,
            require         => File['/var/lib/forj']
  } ->
  exec { "gem1.8 install /var/lib/forj/${unix_cli_version}-${unix_cli_version}.gem":
          path    => ['/bin', '/usr/bin'],
          command => "gem1.8 install --include-dependencies --no-rdoc --no-ri /var/lib/forj/${unix_cli_version}-${unix_cli_version}.gem",
          require => Package['fog'],
          unless  => "gem1.8 list |grep '${unix_cli_name}\s(${unix_cli_version})'",
  }

}
