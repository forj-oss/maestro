# == cacerts::sshgenkeys
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
# generate an sshkey and store it in cacerts_db
#
#

define cacerts::sshgenkeys (
    $username      = $title,  # name of the user account the key belongs to,
                              # key is stored in /user/home/name (~)
    $keyname       = $title,  # name of the key to call it, otherwise defaults
                              # to username
    $for_root      = false,   # puts a copy of the key in /root/.ssh for root
                              # to use as they please
    $do_cacertsdb  = false,   # store the cert on the puppet master cert db
                              # location
    $make_default  = false,   # make the key the default key by copying it to
                              # id_rsa
    $email_address = undef,   # use email address, otherwise we default to
                              # username@domain
    $passphrase    = '',
)
{
  include cacerts::params

  if($email_address == undef)
  {
    $email = "${username}@${::domain}"
  } else
  {
    $email = $email_address
  }

  if($do_cacertsdb == true)
  {
    $target_mode    = 'for cacerts_db'
    $ssh_target_dir = $cacerts::params::ssh_keys_dir
    $sudo_cmd       = ''

  } else
  {
    $target_mode    = "for ${username}"
    $ssh_target_dir = "${cacerts::params::os_home}/${username}/.ssh"
    $sudo_cmd       = "sudo -i -u ${username} "
  }

  $bash     = "${sudo_cmd}bash -c"
  $keyfile  = "${ssh_target_dir}/${keyname}"

# we're using exec here so that we don't have to
# be worried about gerrit users home account
  $keygen = 'ssh-keygen -t rsa'
  $gencmd = "${keygen} -C '${email}' -f ${keyfile} -P \"${passphrase}\""
  exec { "${keyname} : create ${target_mode} ${ssh_target_dir} folder":
          path    => ['/bin', '/usr/bin'],
          command => "${bash} 'mkdir -p ${ssh_target_dir}'",
          onlyif  => "${bash} 'test ! -d ${ssh_target_dir}'",
        } ~>
  exec { "${keyname} : set ${target_mode} ${ssh_target_dir} permissions":
          path    => ['/bin', '/usr/bin'],
          command => "${bash} 'chmod 700 ${ssh_target_dir}'",
        } ->
  exec { "${keyname} : create ${target_mode} sshkeys":
          path    => ['/bin', '/usr/bin'],
          command => "${bash} '${gencmd}'",
          onlyif  => "${bash} 'test ! -f ${ssh_target_dir}/${keyname}'",
        } ~>
  exec { "${keyname} : set permissions for ${keyfile}":
          path    => ['/bin', '/usr/bin'],
          command => "${bash} 'chmod 600 ${keyfile}'",
          onlyif  => "${bash} 'test -f ${keyfile}'",
        } ->
  exec { "${keyname} : set permissions for ${keyfile}.pub":
          path    => ['/bin', '/usr/bin'],
          command => "${bash} 'chmod 600 ${keyfile}.pub'",
          onlyif  => "${bash} 'test -f ${keyfile}.pub'",
        }

  if ($do_cacertsdb == true) and ($::id != 'puppet')
  {
    # Need to change ownership on files created
    # because only puppet must own cacertsdb files
    exec { "${keyname} : set ${target_mode} ${ssh_target_dir} ownership":
            path    => ['/bin', '/usr/bin'],
            command => "bash -c 'chown -R puppet:puppet ${ssh_target_dir}'",
            require => Exec [ "${keyname} : create ${target_mode} sshkeys" ],
        }
  }

  if ( $make_default == true )
  {
    $id_rsa_cp    = "cp ${keyfile} ${ssh_target_dir}/id_rsa"
    $id_rsa_chmod = "chmod 600 ${ssh_target_dir}/id_rsa"
    exec { "${keyname} : setup default key (id_rsa) to be ${keyfile}":
          path    => ['/bin', '/usr/bin'],
          command => "${bash} '${id_rsa_cp};${id_rsa_chmod}'",
          onlyif  => "${bash} 'test ! -f ${ssh_target_dir}/id_rsa'",
          require => Exec["${keyname} : set permissions for ${keyfile}.pub"],
        }
  }

  if ($for_root == true)
  {

    exec { "${keyname} : create /root/.ssh/ folder":
          path    => ['/bin', '/usr/bin'],
          command => 'mkdir -p /root/.ssh',
          onlyif  => 'test ! -d /root/.ssh/',
        } ->
    exec { "${keyname} : set /root/.ssh/ permissions":
          path    => ['/bin', '/usr/bin'],
          command => 'chmod 700 /root/.ssh/',
        } ->
    exec { "${keyname} : setup keys for root ${keyfile}":
          path    => ['/bin', '/usr/bin'],
          command => "cp  ${keyfile} /root/.ssh/${keyname}",
          onlyif  => "test ! -f /root/.ssh/${keyname}",
          require => Exec["${keyname} : set permissions for ${keyfile}.pub"],
        } ->
    exec { "${keyname} : setup keys for root ${keyfile}.pub":
          path    => ['/bin', '/usr/bin'],
          command => "cp ${keyfile}.pub /root/.ssh/${keyname}.pub",
          onlyif  => "test ! -f /root/.ssh/${keyname}.pub",
          require => Exec["${keyname} : set permissions for ${keyfile}.pub"],
      } ->
    exec { "${keyname} : set permissions for /root/.ssh/${keyname}":
          path    => ['/bin', '/usr/bin'],
          command => "chmod 600 /root/.ssh/${keyname}",
          onlyif  => "test -f /root/.ssh/${keyname}",
        } ->
    exec { "${keyname} : perm for /root/.ssh/${keyname}.pub":
          path    => ['/bin', '/usr/bin'],
          command => "chmod 600 /root/.ssh/${keyname}.pub",
          onlyif  => "test -f /root/.ssh/${keyname}.pub",
        }
    if ( $make_default == true )
    {
      $id_rootkey_cp    = "cp ${keyfile} /root/.ssh/id_rsa"
      $id_rootkey_chmod = 'chmod 600 /root/.ssh/id_rsa'
      exec { "${keyname} : setup default key (id_rsa) for /root/.ssh":
            path    => ['/bin', '/usr/bin'],
            command => "${id_rootkey_cp};${id_rootkey_chmod}",
            onlyif  => 'test ! -f /root/.ssh/id_rsa',
            require => Exec["${keyname} : perm for /root/.ssh/${keyname}.pub"],
          }
    }
  }
}