# == Class: ::nodejs_setup
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
# Wrapper calls to nodejs::init class so we can declare it in hiera for puppet 2.x
#
# Can be deprecated in puppet 3.x

class nodejs_wrap (
  $dev_package  = hiera('nodejs_wrap::dev_package', false),
  $manage_repo  = hiera('nodejs_wrap::manage_repo', true),
  $proxy        = hiera('nodejs_wrap::proxy', inline_template('<%= ENV[\'http_proxy\'] %>')),
  $registry     = hiera('nodejs_wrap::registry', undef),
  $version      = hiera('nodejs_wrap::version', '0.10.32-1chl1~precise1'),
)
{
  if $registry == undef
  {
    $registry_url = 'http://registry.npmjs.org/'
  } else
  {
    $registry_url = $registry
  }
  if $proxy {
    if downcase($::operatingsystem) == 'ubuntu'
    {
      $npm_requires = Package['nodejs']
    } else
    {
      $npm_requires = Package['npm']
    }
    exec { 'npm_proxy':
      command => "npm config set proxy ${proxy}",
      path    => $::path,
      require => $npm_requires,
    }
    exec { 'npm_registry': # use a non-https based registry for proxies
      command => "npm config set registry ${registry_url}",
      path    => $::path,
      require => $npm_requires,
    }
  } else
  {
    if $registry != undef # setup the registry because it was passed in
    {
      exec { 'npm_registry':
        command => "npm config set registry ${registry_url}",
        path    => $::path,
        require => $npm_requires,
      }
    }
  }
  class { 'nodejs':
    dev_package => $dev_package,
    manage_repo => $manage_repo,
    version     => $version,
  }
}
