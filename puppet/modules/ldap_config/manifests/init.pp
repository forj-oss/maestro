# == Class: ldap_config
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
class ldap_config(
  $rootpw  = hiera('ldap_config::rootpw'),
  $ssl_cert = hiera('ldap_config::ssl_cert', "/opt/config/cacerts/ca2013/certs/${::fqdn}.crt"),
  $ssl_key  = hiera('ldap_config::ssl_key', "/opt/config/cacerts/ca2013/certs/${::fqdn}.key"),
)
{
  include maestro::cert

  if ($rootpw == undef or $rootpw == '') {
    fail('ERROR! ldap_config::rootpw is required.')
  }

  if ($::maestro_id == undef or $::maestro_id == '') {
    fail('ERROR! maestro_id facter is required.')
  }

  if ($::fqdn == undef or $::fqdn == '') {
    fail('ERROR! fqdn facter is required.')
  }

  $ssl_cert_file_contents = cacerts_getkey($ssl_cert)
  $ssl_key_file_contents = cacerts_getkey($ssl_key)

  if $ssl_cert_file_contents != '' and $ssl_key_file_contents != '' {
    class { 'openldap::server':
      suffix   => "dc=${::maestro_id}",
      ssl_cert => "/opt/config/cacerts/ca2013/certs/${::fqdn}.crt",
      ssl_key  => "/opt/config/cacerts/ca2013/certs/${::fqdn}.key",
    }->
    class { 'ldap_config::defaults':
      rootpw => $rootpw,
    }

  }
}