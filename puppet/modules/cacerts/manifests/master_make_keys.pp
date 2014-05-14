# == cacerts::master_make_keys
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
# Create privately signed certs  :
#
#

define cacerts::master_make_keys (
        $site = $title,
        $domain = '',
        $serial_init = '01',
        $ca_certs_root_dir = '/opt/config/cacerts',
        $environment = $settings::environment,
)
{
  if $environment == '' {
    $environment = $settings::environment
  }
  notify { "created site for ${site}":
          message => join(["************ created site for ${site} **********
             site              = ${site}
             domain            = ${domain}
             ca_certs_root_dir = ${ca_certs_root_dir}
             environment       = ${environment}
         *************************************************" ]),
          require => Cacerts::Cacerts_createssh[$site],
  }
  cacerts::cacerts_createssh { $site:
          domain            => $domain,
          ca_certs_root_dir => $ca_certs_root_dir,
          environment       => $environment,
          serial_init       => $serial_init,
          install_only      => false,
  }
}