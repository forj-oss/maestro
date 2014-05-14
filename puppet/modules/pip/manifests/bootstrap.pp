#
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

# Class: pip::bootstrap
#

class pip::bootstrap ( $pythonver = $title)
{
  include pip::jsongem
  include pip::params
  notify{'completed bootstrap':
    require => [
      Downloader[$::pip::params::ez_setup_url],
      Downloader[$::pip::params::git_pip_url],
    ],
  }

  file { '/var/lib/python-install':
      ensure => directory
  }

  downloader {$::pip::params::ez_setup_url:
    ensure   => present,
    path     => '/var/lib/python-install/ez_setup.py',
    md5      => $::pip::params::ez_setup_md5,
    owner    => 'root',
    group    => 'root',
    mode     => 0755,
    replace  => false,
    provider => url,
    require  => File['/var/lib/python-install'],
  }

  downloader {$::pip::params::git_pip_url:
    ensure   => present,
    path     => '/var/lib/python-install/get-pip.py',
    md5      => $::pip::params::git_pip_md5,
    owner    => 'root',
    group    => 'root',
    mode     => 755,
    replace  => false,
    provider => url,
    require  => Downloader[$::pip::params::ez_setup_url],
  }
}
