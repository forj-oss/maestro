# == cacerts::cacerts_setupdb
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
# setup the default cacerts db for ssh keys
#

define cacerts::cacerts_setupdb (
  $site               = $title,
  $domain             = 'forj.io',
  $ca_certs_root_dir  = '/opt/config/cacerts',
  $environment        = $settings::environment,
  $serial_init        = '01',
  $subject_args    = '/C=US/ST=California/L=Roseville/O=HP/OU=PDE',
)
{
#

# insure python is installed
  include pip::python2
  $static_args     = "--loglevel debug --subject ${subject_args}"
  $domain_args     = "--domain ${domain}"
  $site_args       = "--site ${site}"
  $cacertsdir_args = "--cacerts_dir ${ca_certs_root_dir}"
  $dynamic_args = "${domain_args} ${site_args} ${cacertsdir_args}"
  $create_scrpt = 'python /usr/lib/forj/create_chain.py '


  if !defined(File['/usr/lib/forj'])
  {
    file { '/usr/lib/forj':
      ensure  => directory,
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '2755',
      recurse => true,
    }
  }
  # TODO When all the rest of python scripts have migrated to /usr/lib/forj delete /opt/config/environment/lib
  if !defined(File["/opt/config/${environment}/lib"])
  {
    file { "/opt/config/${environment}/lib":
      ensure  => directory,
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '2755',
      recurse => true,
      require => File["/opt/config/${environment}"],
    }
  }
  if !defined(File["/opt/config/${environment}"])
  {
    file { "/opt/config/${environment}":
      ensure  => directory,
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '2755',
      require => File['/opt/config'],
    }
  }
  if !defined(File['/opt/config'])
  {
    file { '/opt/config':
      ensure  => directory,
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '2755',
    }
  }
  if !defined(File[$ca_certs_root_dir])
  {
    file { $ca_certs_root_dir:
      ensure  => directory,
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '2750',
      require => File['/opt/config'],
    } ->
  # install the ca_certs_root_dir

    file { [
            "${ca_certs_root_dir}/private",
            "${ca_certs_root_dir}/ca2013",
            "${ca_certs_root_dir}/ca2013/certs",
            "${ca_certs_root_dir}/ca2013/newcerts",
            "${ca_certs_root_dir}/ca2013/private",
            "${ca_certs_root_dir}/ca2013/crl",
            ]:
      ensure  => directory,
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '0750',
    } ->
    cacerts::cacerts_setupdb_staticfiles { [
                                    'util.py',
                                    'create_chain.py',
                                    'create_servercert.py',
                                    'Colorer.py',
                                    ]:
            targetpath => '/usr/lib/forj',
            modulepath => 'puppet:///modules/cacerts/scripts',
            mode       => '0555',
            require    => File['/usr/lib/forj'],
    } ->
    cacerts::cacerts_setupdb_staticfiles { [
                                    'openssl.cnf',
                                    ]:
            targetpath => $ca_certs_root_dir,
            modulepath => 'puppet:///modules/cacerts/ca_certs_db',
            mode       => '0755',
    } ->
    file { [
              "${ca_certs_root_dir}/serial",
              "${ca_certs_root_dir}/ca2013/serial",
          ]:
            ensure  => present,
            content => $serial_init,
            owner   => 'puppet',
            group   => 'puppet',
            mode    => '0765',
            replace => false,
    } ->
    exec { 'create_chain.py':
        path    => ['/bin', '/usr/bin'],
        command => join([$create_scrpt,
                          $static_args ,
                          ' ' ,
                          $dynamic_args]),
        creates => ["${ca_certs_root_dir}/private/cakey.pem",
                    "${ca_certs_root_dir}/ca2013/private/cakey.pem",
                    "${ca_certs_root_dir}/private/cakey.key",
                    "${ca_certs_root_dir}/ca2013/ca2013.csr",
                    "${ca_certs_root_dir}/ca2013/cacert.pem",
                    "${ca_certs_root_dir}/ca2013/chain.crt",
                    "${ca_certs_root_dir}/cacert.pem",
                    "${ca_certs_root_dir}/intermediate.cer",
                    "${ca_certs_root_dir}/root.cer",
                    "${ca_certs_root_dir}/index.txt",
                    ]
      }

  }
}