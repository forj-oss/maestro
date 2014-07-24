# Define: maestro::backup::manage_backup
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
class maestro::backup::manage_backup(
  $applications   = hiera_hash('maestro::backup::set_app_backup', undef),
) {

  if ($applications  ==  undef  or  $applications  ==  '')
  {
    notice('WARNING, hiera parameter maestro::backup::set_app_backup is empty, there is not backups configured for this box.')
  }
  else
  {
    $backup_items = keys($applications)
    maestro::backup::set_app_backup { $backup_items:
      applications => $applications
    }
  }
}