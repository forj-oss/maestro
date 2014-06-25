# == cacerts::add_ssh_host
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
define cacerts::add_ssh_host (
  $host_alias    = $title,
  $host_address  = undef,
  $host_user     = '',
  $local_user    = 'root',
  $keyfile_name  = '',
)
{
  if $local_user == 'root' {
    $home = '/root'
  }
  else {
    $home = "/home/${local_user}"
  }

  $host_exists_cmd = "bash -c '! grep -q ${host_alias} ${home}/.ssh/config'"

  if($host_alias != '' and $host_alias != undef)
  {
    if($host_address != '' and $host_address != undef)
    {
      file { "${home}/.ssh/config":
        ensure => file,
        mode   => '0644',
      }->
      exec { "ssh ${host_alias}" :
        command => "printf 'host ${host_alias}\n\thostname ${host_address}\n\tuser ${host_user}\n\tStrictHostKeyChecking no\n\tidentityfile ${home}/.ssh/${keyfile_name}\n'>> ${home}/.ssh/config",
        onlyif  => $host_exists_cmd,
        path    => ['/bin','/usr/bin'],
      }
    }
    else
    {
      warning('cacerts::add_ssh_host: host_address is undefined or empty, skipping add_ssh_host')
    }
  }
  else
  {
    warning('cacerts::add_ssh_host:host_alias is undefined, skipping.')
  }
}
