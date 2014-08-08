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
#
# Class: pip::python2
class pip::python2 {
  include pip::params
  include pip::bootstrap

  package { $::pip::params::python_devel_package:
    ensure => present,
  }

  package { $::pip::params::python_setuptools_package:
    ensure => absent,
  }

  package { $::pip::params::python_pip_package:
    ensure  => absent,
  }

  exec { 'install_setuptools2':
    command   => 'python2 /var/lib/python-install/ez_setup.py',
    path      => '/bin:/usr/bin',
    subscribe => Downloader[$::pip::params::ez_setup_url],
    creates   => $::pip::params::setuptools_pth,
    require   => [
      Package[$::pip::params::python_devel_package],
      Class['pip::bootstrap'],
    ],
  }

  exec { 'install_pip2':
    command   => 'python2 /var/lib/python-install/get-pip.py',
    path      => '/bin:/usr/bin',
    subscribe => Downloader[$::pip::params::git_pip_url],
    creates   => $::pip::params::pip_executable,
    require   => Exec['install_setuptools2'],
  }
}
