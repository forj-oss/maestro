# Class: dashboard::maintjobs
#
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
#
# This module executes maintenance cron jobs to puppet dashboard
#
# Parameters:
# none
#
# Actions:
# (1) Verifies if puppet dashboard worker is running, if not it starts one
# (2) Deletes old puppet dashboard reports
# (3) Optimizes puppet dashboard mysql tables

# Sample Usage:
# puppet apply -e "include puppetmaster::maintjobs" --modulepath=/opt/config/production/git/maestro/puppet/modules

#
class puppet::dashboard::maintjobs(
  $status           = enabled,
  $environment      = $settings::environment,
)
{
  if $status == enabled
  {
    require puppet::dashboard::configure
    require puppet::master_extras
    #(1) Verifies if puppet dashboard worker is running, if not it starts one
    if defined (Class['dashboard'])
    {
      file { '/usr/share/puppet-dashboard/puppet-dashboard-start-worker.sh':
        ensure   => file,
        owner    => 'root',
        mode     => '0755',
        source   => 'puppet:///modules/puppet/puppet-dashboard-start-worker.sh',
      }

      cron { 'puppet-dashboard-start-worker':
        command     => '/usr/share/puppet-dashboard/puppet-dashboard-start-worker.sh',
        user        => 'root',
        hour        => '*/1',
        minute      => '10',
        environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
        require     => File['/usr/share/puppet-dashboard/puppet-dashboard-start-worker.sh'],
      }

      # (2) Deletes old puppet dashboard reports
      file { '/usr/share/puppet-dashboard/puppet-dashboard-mysql-prune.sh':
        ensure   => file,
        owner    => 'root',
        mode     => '0755',
        source   => 'puppet:///modules/puppet/puppet-dashboard-mysql-prune.sh',
      }

      cron { 'puppet-dashboard-mysql-prune':
        command     => '/usr/share/puppet-dashboard/puppet-dashboard-mysql-prune.sh',
        user        => 'root',
        monthday    => '*/2',
        minute      => '20',
        hour        => '7',
        environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
        require     => File['/usr/share/puppet-dashboard/puppet-dashboard-mysql-prune.sh'],
      }

      # (3) Optimizes puppet dashboard mysql tables
      file { '/usr/share/puppet-dashboard/puppet-dashboard-mysql-optimize.sh':
        ensure   => file,
        owner    => 'root',
        mode     => '0755',
        source   => 'puppet:///modules/puppet/puppet-dashboard-mysql-optimize.sh',
      }
      cron { 'puppet-dashboard-mysql-optimize':
        command     => '/usr/share/puppet-dashboard/puppet-dashboard-mysql-optimize.sh',
        user        => 'root',
        hour        => '12',
        minute      => '30',
        environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
        require     => File['/usr/share/puppet-dashboard/puppet-dashboard-mysql-optimize.sh'],
      }
    }
  }
}
