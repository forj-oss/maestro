# == Class: ldap_config::defaults
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
class ldap_config::defaults(
  $rootpw       = hiera('ldap_config::rootpw'),
  $pwdldifsh    = hiera('ldap_config::defaults::pwdldif', '/usr/lib/forj/pwdldif.sh'),
  $pwdldif      = hiera('ldap_config::defaults::pwdldif', '/usr/lib/forj/pwd.ldif'),
  $defaultldif  = hiera('ldap_config::defaults::$defaultldif', '/usr/lib/forj/forj-default.ldif'),
  $description  = hiera('ldap_config::defaults::description', 'Forj'),
  $domain       = hiera('ldap_config::defaults::domain', $::domain),
  $user         = hiera('ldap_config::defaults::user','puppet'),
  $group        = hiera('ldap_config::defaults::group','puppet'),
  $mode         = hiera('ldap_config::defaults::mode','0755'),
) {

  validate_string($pwdldif)
  validate_string($defaultldif)
  validate_string($description)
  validate_string($domain)
  validate_string($user)
  validate_string($group)
  validate_string($mode)

  if ($rootpw == undef or $rootpw == '') {
    fail('ERROR! ldap_config::rootpw is required.')
  }

  if ($::maestro_id == undef or $::maestro_id == '') {
    fail('ERROR! maestro_id facter is required.')
  }

  file { $pwdldifsh:
    ensure  => 'present',
    content => template('ldap_config/pwdldif.sh.erb'),
    owner   => $user,
    group   => $group,
    mode    => $mode,
  }

  file { $defaultldif :
    ensure  => 'present',
    content => template('ldap_config/forj-default.ldif.erb'),
    owner   => $user,
    group   => $group,
    mode    => $mode,
  }

  exec { 'pwd-ldif-sh':
    command => "${pwdldifsh} '${rootpw}'",
    path    => $::path,
    require => File[$pwdldifsh],
  }

  exec { 'ldapmodify-forj-default-ldif':
    command => "ldapmodify -h 127.0.0.1 -a -f ${defaultldif} -D 'cn=admin,dc=${::maestro_id}' -w '${rootpw}'",
    path    => $::path,
    require => [ File[$defaultldif], Exec['pwd-ldif-sh'] ],
    unless  => "ldapsearch -h 127.0.0.1 -x -D 'cn=admin,dc=${::maestro_id}' -w '${rootpw}' -b 'ou=people,o=${domain},dc=${::maestro_id}'",
  }
}