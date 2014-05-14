# == cacerts::known_hosts
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
# generate known_host entry for server
#
#

define cacerts::known_hosts (
    $username      = $title,
    $keyname       = $title,
    $for_root      = false,
    $environment   = $settings::environment,
    $hostname      = 'localhost',
    $portnum       = '22',
    $manage_sshdir = true,
)
{
  $sudo_cmd     = "sudo -i -u ${username}"
  $python_cmd   = 'python'
  $sudo_python  = "${sudo_cmd} ${python_cmd}"

  $gen_known_py = "/opt/config/${environment}/lib/gen_known_hosts.py"
  $srv_opt      = "--server_host ${hostname}"
  $port_opt     = "--server_port ${portnum}"

  if($hostname != '' and $hostname != '#' and $hostname != undef)
  {
    #TODO (see user story #2016): this refrence should be removed and converted into a module refrence for gen_known_hosts.py instead.
    include gerrit_config::pyscripts

    if(! defined(File["/home/${username}/.ssh"]) and $manage_sshdir)
    {
      file { "/home/${username}/.ssh":
          ensure  => directory,
          owner   => $username,
          group   => $username,
          mode    => '0700',
          recurse => true,
        }
    }

    exec { "update known_hosts for ${username} clean log":
              path    => ['/bin', '/usr/bin'],
              command => 'chmod 666 /tmp/gen_known_hosts.log',
              onlyif  => 'test -f /tmp/gen_known_hosts.log',
        } ->
    exec { "update known_hosts for ${username} ":
            path    => ['/bin', '/usr/bin'],
            command => "${sudo_python} ${gen_known_py} ${srv_opt} ${port_opt}",
            require => File["/home/${username}/.ssh"],
          }

    if($for_root == true)
    {
      if(! defined(File['/root/.ssh']))
      {
        file { '/root/.ssh':
          ensure  => directory,
          owner   => 'root',
          group   => 'root',
          mode    => '0700',
          recurse => true,
        }
      }
      exec { 'update known_hosts for root clean log':
              path    => ['/bin', '/usr/bin'],
              command => 'chmod 666 /tmp/gen_known_hosts.log',
              onlyif  => 'test -f /tmp/gen_known_hosts.log',
        } ->
      exec { 'update known_hosts for root ':
          path    => ['/bin', '/usr/bin'],
          command => "${python_cmd} ${gen_known_py} ${srv_opt} ${port_opt}",
          require => File['/root/.ssh'],
        }
    }
  }
  else
  {
    notify{"WARNING, ${hostname}, hostname is empty,
           can't proceed with known_hosts creation.":}
  }
}