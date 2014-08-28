# == Class: ldap::server::master
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
# Puppet module to manage server configuration for
# **OpenLdap**.
#
#
#
class ldap::server::master(
  $suffix,
  $rootpw,
  $rootdn              = "cn=admin,${suffix}",
  $schema_inc          = [],
  $modules_inc         = [],
  $index_inc           = [],
  $log_level           = '0',
  $bind_anon           = true,
  $ssl                 = false,
  $ssl_ca              = false,
  $ssl_cert            = false,
  $ssl_key             = false,
  $ssl_ca_content      = '',
  $ssl_cert_content    = '',
  $ssl_key_content     = '',
  $syncprov            = false,
  $syncprov_checkpoint = '100 10',
  $syncprov_sessionlog = '100',
  $sync_binddn         = false,
  $enable_motd         = false,
  $ensure              = present
  )
  {

  include ldap::params

  if($enable_motd) {
    motd::register { 'ldap::server::master': }
  }

# lets install also client-side tools (to debug the ldap server locally)
  $ldap_pkgs = [$ldap::params::server_package, $ldap::params::package]
  package { $ldap_pkgs:
    ensure => $ensure
  }

  service { $ldap::params::service:
    ensure     => running,
    enable     => true,
    pattern    => $ldap::params::server_pattern,
    require    => [
      Package[$ldap::params::server_package],
      File["${ldap::params::prefix}/${ldap::params::server_config}"],
      ]
  }

  File {
    mode    => '0640',
    owner   => $ldap::params::server_owner,
    group   => $ldap::params::server_group,
  }

  $what_is_required = $ssl ? {
    false => [
                Package[$ldap::params::server_package],
    ],
    true  => [
                Package[$ldap::params::server_package],
                File['ssl_ca'],
                File['ssl_cert'],
                File['ssl_key'],
    ]
  }

  file { "${ldap::params::prefix}/${ldap::params::server_config}":
    ensure  => $ensure,
    content => template("ldap/${ldap::params::server_config}.erb"),
    notify  => Service[$ldap::params::service],
    require => $what_is_required
  }

  if($ssl) {

    if $ssl_ca_content != '' {
      file { 'ssl_ca':
        path    => "${ldap::params::ssl_prefix}/${ssl_ca}",
        content => $ssl_ca_content,
      }
    }
    else { fail('no data for: /ca2013/certs/chain.crt') }

    if $ssl_cert_content != '' {
      file { 'ssl_cert':
        path    => "${ldap::params::ssl_prefix}/${ssl_cert}",
        content => $ssl_cert_content,
      }
    }
    else { fail("no data for: /ca2013/certs/${::fqdn}.crt") }

    if $ssl_key_content != '' {
      file { 'ssl_key':
        path    => "${ldap::params::ssl_prefix}/${ssl_key}",
        content => $ssl_key_content,
      }
    }
    else { fail("no data for: /ca2013/certs/${::fqdn}.key") }


    $the_provider = $::puppetversion ? {
                  /^3./   => 'shell',
                  /^2.7/  => 'shell',
                  /^2.6/  => 'posix',
                  default => 'posix'
    }
    # Create certificate hash file
    exec { 'Server certificate hash':
      command  => "ln -s ${ldap::params::ssl_prefix}/${ssl_cert} ${ldap::params::cacertdir}/$(openssl x509 -noout -hash -in ${ldap::params::ssl_prefix}/${ssl_cert}).0",
      unless   => "test -f ${ldap::params::cacertdir}/$(openssl x509 -noout -hash -in ${ldap::params::ssl_prefix}/${ssl_cert}).0",
      provider => $the_provider,
      require  => File['ssl_cert']
    }

  }

  # Additional configurations (for rc scripts)
  case $::osfamily {

    'Debian' : {
      class { 'ldap::server::debian': }
    }

    default: {
      fail("OS is not supported (${::osfamily})")
    }

  }

}
