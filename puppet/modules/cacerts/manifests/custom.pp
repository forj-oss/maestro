# == Class: cacerts::custom
#
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
# Install a custom https cert into ca_certs_db/custom
#
# In addition we will attempt to unprotect any cert being managed.
# 1) save an encrypted password into /etc/puppet/hieradata/common.eyaml on your puppetmaster.
# 2)cd /etc/puppet/secure;eyaml encrypt -l 'cacerts::custom::ca_pass' -s 'thepassword' | grep "cacerts::custom::ca_pass: ENC" >> /etc/puppet/hieradata/common.eyaml
class cacerts::custom
(
  $ca_pass      = hiera('cacerts::custom::ca_pass',undef),
  $ca_certs_db  = hiera('cacerts::ca_certs_db','/opt/config/cacerts'),
  $source       = hiera('cacerts::custom::source',undef),  # 'puppet:///modules/custom_certs/certs'  This is the module holding the custom certs
)
{
  if $ca_pass != undef
  {
    if (!defined(File["${ca_certs_db}/custom"])) and $source != undef {
      file { "${ca_certs_db}/custom":
        ensure  => present,
        source  => $source,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '0640',
        recurse => true,
      }
    }
    elsif (!defined(File["${ca_certs_db}/custom"])) # we still need a folder
    {
      file { "${ca_certs_db}/custom":
        ensure  => directory,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '0640',
      }
    }
    cacerts::unprotect{"${ca_certs_db}/custom":
      pass    => $ca_pass,
      require => File["${ca_certs_db}/custom"],
    }
  } else
  {
    warning('unable to place custom certs without a password in cacerts::ca_pass')
  }
}

