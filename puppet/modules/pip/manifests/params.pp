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
# Class: pip::params
#
# This class holds parameters that need to be
# accessed by other classes.
class pip::params {
  case $::osfamily {
    'RedHat': {
      $python_devel_package       = 'python-devel'
      $python_pip_package         = 'python-pip'
      $python_setuptools_package  = 'python-setuptools'
      $python3_devel_package      = 'python3-devel'
      $python3_pip_package        = 'python3-pip'
      $python3_setuptools_package = 'python3-setuptools'
      $pip_executable             = '/usr/bin/pip'
      $pip3_executable            = '/usr/bin/pip3'
      $setuptools_pth             = '/usr/local/lib/python2.7/dist-packages/setuptools.pth'
      $setuptools3_pth            = '/usr/lib/python2.7/site-packages/setuptools.pth'
    }
    'Debian': {
      $python_devel_package       = 'python-all-dev'
      $python_pip_package         = 'python-pip'
      $python_setuptools_package  = 'python-setuptools'
      $python3_devel_package      = 'python3-all-dev'
      $python3_pip_package        = 'python3-pip'
      $python3_setuptools_package = 'python3-setuptools'
      $pip_executable             = '/usr/local/bin/pip'
      $pip3_executable            = '/usr/local/bin/pip3'
      $setuptools_pth             = '/usr/local/lib/python2.7/dist-packages/setuptools.pth'
      $setuptools3_pth            = '/usr/lib/python3.3/site-packages/setuptools.pth'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'pip' module only supports osfamily Debian or RedHat.")
    }
  }
  $ez_setup_url = 'https://bitbucket.org/pypa/setuptools/raw/39f7ef5ef22183f3eba9e05a46068e1d9fd877b0/ez_setup.py'
  $ez_setup_md5 = '96abe6ebc5d711f476b614d07bd37be3'

  $git_pip_url = 'https://raw.github.com/pypa/pip/8575e0c16424bcc9866baa0f9f779f1b524fbc20/contrib/get-pip.py'
  $git_pip_md5 = '49808f380bf193aef5be27e2d7f90503'
}
