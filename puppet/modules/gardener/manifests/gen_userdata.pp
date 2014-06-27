# == gardener::gen_userdata
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
# generate the user data required to create a server
#
#
define gardener::gen_userdata (
  $site        = $title,
  $domain      = '',
  $userdata    = '/tmp/mime.txt',
  $t_full_q_hostname = '',
  $t_site            = '',
  $http_proxy        = '',
  $template          = undef,
)
{
  Exec { path => [  '/usr/local/bin',
                    '/bin/',
                    '/sbin/',
                    '/usr/bin/',
                    '/usr/sbin/',
                    '/var/lib/gems/1.8/gems/hpcloud-1.9.1/bin/'
          ] }

  if $template != undef
  {
    $metadata = to_json(to_hash(split($template['meta_data'],',')))
  } else {
    $metadata = ''
  }
  # we do this so that pinas can templify the hostname of the target
  # server. or we can offer an alternate hostname that will be registered
  # in puppet.conf certname
  if $t_full_q_hostname == ''
  {
    $full_q_hostname = "${site}.${domain}"
  }
  else
  {
    $full_q_hostname = $t_full_q_hostname
  }
  if $t_site == ''
  {
    $site_name = $site
  }
  else
  {
    $site_name = $t_site
  }
  $python_run = "python ./write-mime-multipart.${site}.py"
  $u1 = "./boothook.${site}.sh:text/cloud-boothook"
  $u2 = "./cloud-config-node.${site}.yaml"
  $u3 = "./boot-node.${site}.sh"
  $u4 = "-o ${userdata}"
  $create_udata = "${python_run} ${u1} ${u2} ${u3} ${u4}"
  $gardner_script_dir = 'puppet:///modules/gardener/scripts'
  file { "/tmp/write-mime-multipart.${site}.py":
        ensure  => present,
        mode    => '0555',
        source  => "${gardner_script_dir}/write-mime-multipart.py",
        replace => true,
      } ->
  file { "/tmp/boothook.${site}.sh":
    ensure  => present,
    content => template('gardener/boothook.sh.erb'),
    replace => true,
  } ->
  file { "/tmp/boot-node.${site}.sh":
    ensure  => present,
    content => template('gardener/boot-node.sh.erb'),
    replace => true,
  } ->
  file { "/tmp/cloud-config-node.${site}.yaml":
    ensure  => present,
    content => template('gardener/cloud-config-node.yaml.erb'),
    replace => true,
  }->
  exec { "create ${userdata}":
    command     => $create_udata,
    cwd         => '/tmp',
  }->
  exec { "dos2unix for ${userdata}":
    command     => "dos2unix ${userdata}",
    require     => Package['dos2unix'],
  }
}
