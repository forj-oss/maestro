# == Class: ldap
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
# Puppet module to manage client and server configuration for
# **OpenLdap**.
#
#
class ldap(
  $uri,
  $base,
  $version        = '3',
  $timelimit      = 30,
  $bind_timelimit = 30,
  $idle_timelimit = 60,
  $binddn         = false,
  $bindpw         = false,
  $ssl            = false,
  $ssl_cert       = false,
  $ssl_cert_content = '',
  $nsswitch   = false,
  $nss_passwd = false,
  $nss_group  = false,
  $nss_shadow = false,

  $pam            = false,
  $pam_att_login  = 'uid',
  $pam_att_member = 'member',
  $pam_passwd     = 'md5',
  $pam_filter     = 'objectClass=posixAccount',

  $enable_motd    = false,
  $ensure         = present) {

  include ldap::params

  if($enable_motd) {
    motd::register { 'ldap': }
  }

  package { $ldap::params::package:
    ensure => $ensure,
  }

  File {
    ensure  => $ensure,
    mode    => '0644',
    owner   => $ldap::params::owner,
    group   => $ldap::params::group,
  }

  $ens = $ensure ? {
                present => directory,
                default => absent,
  }
  file { $ldap::params::prefix:
    ensure  => $ens,
    require => Package[$ldap::params::package],
  }

  file { "${ldap::params::prefix}/${ldap::params::config}":
    content => template("ldap/${ldap::params::config}.erb"),
    require => File[$ldap::params::prefix],
  }

  if($ssl) {

    if(!$ssl_cert) {
      fail('When ssl is enabled you must define ssl_cert (filename)')
    }
    if($ssl_cert_content == '') {
      fail('When ssl is enabled you must define ssl certificate contents')
    }

    file { "${ldap::params::cacertdir}/${ssl_cert}":
      ensure => $ensure,
      owner  => 'root',
      group  => $ldap::params::group,
      source => $ssl_cert_content
    }

    # Create certificate hash file
    exec { 'Build cert hash':
      command => "ln -s ${ldap::params::cacertdir}/${ssl_cert} ${ldap::params::cacertdir}/$(openssl x509 -noout -hash -in ${ldap::params::cacertdir}/${ssl_cert}).0",
      unless  => "test -f ${ldap::params::cacertdir}/$(openssl x509 -noout -hash -in ${ldap::params::cacertdir}/${ssl_cert}).0",
      require => File["${ldap::params::cacertdir}/${ssl_cert}"]
    }
  }

  $mod_type = $ensure ? {
                    'present' => 'ldap',
                    default   => 'none'
  }
  # require module nsswitch
  if($nsswitch == true) {
    class { 'nsswitch':
      uri         => $uri,
      base        => $base,
      module_type => $mod_type,
    }
  }

  # require module pam
  if($pam == true) {
    Class ['pam::pamd'] -> Class['ldap']
  }

}
