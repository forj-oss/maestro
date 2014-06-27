# == maestro::requirements
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
# requirements needed to run sails and node js stuff
#
#

class maestro::requirements(
  $packages_hash = hiera_hash('maestro::requirements',undef) #we provide a way to override these requirements from yaml.
) {

  if $packages_hash != undef
  {
    $package_data = $packages_hash
  } else
  {
    $package_data = parseyaml("
  sails:
    ensure: '0.9.13'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  pm2:
    ensure: '0.8.2'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  forever:
    ensure: '0.10.11'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  optimist:
    ensure: '0.6.1'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  restify:
    ensure: '2.6.3'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  path:
    ensure: '0.4.9'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  mysql:
    ensure: '2.1.1'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  js-yaml:
    ensure: '3.0.2'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  async:
    ensure: '0.2.10'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  validator:
    ensure: '3.5.1'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
  openid:
    ensure: '0.5.5'
    provider: 'npm'
    require: 'Class[nodejs_wrap]'
")
  }
  $packages = keys($package_data)
  packages::versioned { $packages:
      data => $package_data,
  }

}
