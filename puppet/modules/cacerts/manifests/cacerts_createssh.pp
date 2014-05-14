# == cacerts::cacerts_createssh
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
# create ssh cert
#

define cacerts::cacerts_createssh (
  $site              = $title,
  $domain            = 'forj.io',
  $ca_certs_root_dir = '/opt/config/cacerts',
  $environment       = $settings::environment,
  $serial_init       = '01',
  $install_only      = true,
  $subject_args    = '/C=US/ST=California/L=Roseville/O=HP/OU=PDE'
)
{
# python ${files}/scripts/create_servercert.py --loglevel debug
#         --domain ${domain}
#         --subject /C=US/ST=California/L=Roseville/O=HP/OU=PDE
#         --site ${site}
#         --altnames "alternate.dns.names"
#         --cacerts_dir ${ca_certs_root_dir}


  $static_args     = "--loglevel debug --subject ${subject_args}"
  $domain_args     = "--domain ${domain}"
  $site_args       = "--site ${site}"
  $cacertsdir_args = "--cacerts_dir ${ca_certs_root_dir}"
  $dynamic_args = "${domain_args} ${site_args} ${cacertsdir_args}"
  $create_scrpt = 'python /usr/lib/forj/create_servercert.py '

  cacerts::cacerts_setupdb{$site:
      domain            => $domain,
      ca_certs_root_dir => $ca_certs_root_dir,
      environment       => $environment,
      serial_init       => $serial_init,
  }
  # create the server certificate

  if $install_only {
      notify { "install_caroots_only ${site}":
        message => "********* only installing ${ca_certs_root_dir} **********",
        require =>  Cacerts::Cacerts_setupdb[$site],
      }
  }
  else
  {
      notice("************ creating certs for ${site} **********")
      exec { "create_servercert_for_${site}":
        path    => ['/bin', '/usr/bin'],
        command => join([$create_scrpt,
                          $static_args ,
                          ' ' ,
                          $dynamic_args]),
        require =>  Cacerts::Cacerts_setupdb[$site],
        creates => ["${ca_certs_root_dir}/ca2013/certs/${site}.${domain}.crt",
                    "${ca_certs_root_dir}/ca2013/certs/${site}.${domain}.csr",
                    "${ca_certs_root_dir}/ca2013/certs/${site}.${domain}.key"]
      }
  }
}