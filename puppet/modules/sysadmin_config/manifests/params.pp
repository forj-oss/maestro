# Class: sysadmin_config::params
#
# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
#
# This class holds parameters that need to be
# accessed by other classes.
class sysadmin_config::params {
  case $::osfamily {
    'RedHat': {
      $packages = ['puppet', 'wget']
      $user_packages = ['byobu', 'emacs-nox']
      $update_pkg_list_cmd = ''
    }
    'Debian': {
      $packages = ['puppet', 'wget']
      $user_packages = ['byobu', 'emacs23-nox']
      $update_pkg_list_cmd = 'apt-get update >/dev/null 2>&1;'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'openstack_project' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
