# == jimador::requirements
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
# check for json
#
#

class jimador::requirements {

  tag 'jimador::requirements'
  $package_data = $::operatingsystem ? {
    Ubuntu => parseyaml("
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
  libxslt-dev:
    ensure: 'latest'
"),
    CentOS => parseyaml("
  make:
    ensure: 'latest'
    require: 'Package[libxslt-devel]'
  mime-types:
    ensure: '1.25.1'
    provider: 'gem'
    require: 'Package[make]'
  excon:
    ensure: '0.31.0'
    provider: 'gem'
    require: 'Package[mime-types]'
  json:
    ensure: 'latest'
    provider: 'gem'
    require: 'Package[excon]'
  libxslt-devel:
    ensure: 'latest'
"),
    default => parseyaml("
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
  libxslt-dev:
    ensure: 'latest'
"),
}
  $packages = keys($package_data)
  jimador::requirements_package { $packages:
      data => $package_data,
  }

}
