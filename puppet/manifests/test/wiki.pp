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
#TODO: create specs / test directory and move this.
#
# setup a test wiki server
#

# info about mediawiki:
#
# https://www.mediawiki.org/wiki/MediaWiki
#

node default {
  # we need to set it to what our vagrant hostname for fqdn will be
  $instance_name = 'maestro'
  $instance_id = '42'
  $instance_dom = 'localhost'
  maestro::orchestrator::gencerts {$instance_name :
      domain      => $instance_dom,
      instance_id => $instance_id,
      serial_init => '01',
  }
  $ssl_cert_file_contents = ''
  $ssl_key_file_contents = ''
  $ssl_chain_file_contents = ''
  if $ssl_cert_file_contents == '' {
    $ssl_cert_file_data = cacerts_getkey(join([$ca_certs_db ,
                                          "/ca2013/certs/${instance_name}.${instance_id}.${instance_dom}.crt"]))
  } else {
    $ssl_cert_file_data = $ssl_cert_file_contents
  }

  if $ssl_key_file_contents == '' {
    $ssl_key_file_data = cacerts_getkey(join([$ca_certs_db , "/ca2013/certs/${instance_name}.${instance_id}.${instance_dom}.key"]))
  } else {
    $ssl_key_file_data = $ssl_key_file_contents
  }

  if $ssl_chain_file_contents == '' {
    $ssl_chain_file_data = cacerts_getkey(join([$ca_certs_db ,
                                        '/ca2013/chain.crt']))
  } else {
    $ssl_chain_file_data = $ssl_chain_file_contents
  }
  if $ssl_cert_file_data == ''
  {
    class { 'openstack_project::wiki':
  #    mysql_root_password     => hiera('wiki_db_password'),
  #    sysadmins               => hiera('sysadmins'),
  #    ssl_cert_file_contents  => hiera('wiki_ssl_cert_file_contents'),
  #    ssl_key_file_contents   => hiera('wiki_ssl_key_file_contents'),
  #    ssl_chain_file_contents => hiera('wiki_ssl_chain_file_contents'),

      mysql_root_password     => 'changeme',
      sysadmins               => [],
      ssl_cert_file_contents  => $ssl_cert_file_data,
      ssl_key_file_contents   => $ssl_key_file_data,
      ssl_chain_file_contents => $ssl_chain_file_data,
      require                 => Maestro::Orchestrator::Gencerts[$instance_name],
    }
  }
}


# vim:sw=2:ts=2:expandtab:textwidth=79
