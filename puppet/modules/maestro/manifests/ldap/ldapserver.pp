# == Class: maestro::ldap:ldapserver
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
class maestro::ldap::ldapserver
{
  $ca_certs_db = hiera('maestro::certs_dir' ,'/opt/config/cacerts')
  $ssl_ca_file_contents = cacerts_getkey(join([$ca_certs_db , '/ca2013/chain.crt']))
  $ssl_cert_file_contents = cacerts_getkey(join([$ca_certs_db , "/ca2013/certs/${::fqdn}.crt"]))
  $ssl_key_file_contents = cacerts_getkey(join([$ca_certs_db , "/ca2013/certs/${::fqdn}.key"]))

  include maestro::cert

  if $ssl_ca_file_contents != '' and $ssl_cert_file_contents != '' and $ssl_key_file_contents != '' {
    # split fqdn facter (ie. maestro.ys.dev.forj.io) into LDAP dc entries..
    # result: dc=maestro,dc=ys,dc=dev,dc=forj,dc=io
    $suffix = split($::fqdn,'.')
    class { 'ldap::server::master':
      suffix           => "dc=${$suffix[0]},dc=${$suffix[1]},dc=${$suffix[2]},dc=${$suffix[3]},dc=${$suffix[4]}",
      rootpw           => '$Changeme01',
      ssl              => true,
      ssl_ca           => 'ca.pem',
      ssl_cert         => 'master-ldap.pem',
      ssl_key          => 'master-ldap.key',
      ssl_ca_content   => $ssl_ca_file_contents,
      ssl_cert_content => $ssl_cert_file_contents,
      ssl_key_content  => $ssl_key_file_contents,
      require          => Class['maestro::cert']
    }
  }
}
