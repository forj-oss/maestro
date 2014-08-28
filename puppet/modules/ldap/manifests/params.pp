# == Class: ldap::params
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

class ldap::params {

  case $::osfamily {

    'Debian' : {

      $package   = [ 'ldap-utils' ]

      $prefix    = '/etc/ldap'
      $owner     = 'root'
      $group     = 'root'
      $config    = 'ldap.conf'
      $cacertdir = '/etc/ssl/certs'

      $service         = 'slapd'
      $server_pattern  = 'slapd'
      $server_package  = [ 'slapd' ]
      $server_config   = 'slapd.conf'
      $server_owner    = 'openldap'
      $server_group    = 'openldap'
      $db_prefix       = '/var/lib/ldap'
      $ssl_prefix      = '/etc/ssl/certs'
      $server_run      = '/var/run/openldap'

      case $::operatingsystemmajrelease {
        5 : {

          case $::architecture {
            /^amd64/: {
              $module_prefix = '/usr/lib64/ldap'
            }

            /^i?[346]86/: {
              $module_prefix = '/usr/lib/ldap'
            }

            default: {
              fail("Architecture not supported (${::architecture})")
            }

          }

        }

        default : {
              $module_prefix = '/usr/lib/ldap'
        }

      }

      $modules_base  = [ 'back_bdb' ]

      $schema_prefix   = "${prefix}/schema"
      $schema_base     = [ 'core', 'cosine', 'nis', 'inetorgperson', ]
      $index_base      = [
        'index objectclass  eq',
        'index entryCSN     eq',
        'index entryUUID    eq',
        'index uidNumber    eq',
        'index gidNumber    eq',
        'index cn           pres,sub,eq',
        'index sn           pres,sub,eq',
        'index uid          pres,sub,eq',
        'index displayName  pres,sub,eq',
        ]

    }

    default:  {
      fail("Operating system ${::operatingsystem} not supported")
    }

  }

}
