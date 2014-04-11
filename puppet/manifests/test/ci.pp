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
#
# This manifest file is currently for testing under vagrant

#TODO: create specs / test directory and move this.
$mysql_password = 'changeme'
$mysql_root_password = 'changeme'

#
# this is the jenkins/zuul server
node /.*(ci|precise32).*/ {

  # enable salt minion
  class {'salt':}

  # TODO: Read graphite_url from graphite not pastebin

  $graphite_url = read_json('pastebin','tool_url',$::json_config_location,true)
  $ca_certs_db = '/opt/config/cacerts'
  $jenkins_private_key = cacerts_getkey(
    join( [ $ca_certs_db, '/ssh_keys/jenkins' ])
  )

  # last parameter is a flag to get the url as ip format only or include their
  # prefix ex http:// or https://
  $gerrit_url = read_json('gerrit','tool_url',$::json_config_location,true)
  if ( $jenkins_private_key ) != '' and ( $gerrit_url != '' ) {
    class { 'cdk_project::jenkins':
      vhost_name                        => $node_vhost,
      jenkins_jobs_password             => '',
      manage_jenkins_jobs               => true,
      ssl_cert_file_contents            => '',
      ssl_key_file_contents             => '',
      ssl_chain_file_contents           => '',
      jenkins_ssh_private_key           => $jenkins_private_key,
      zmq_event_receivers               => [],
      sysadmins                         => [],
      ca_certs_db                       => $ca_certs_db,
      gerrit_server                     => $gerrit_url,
      gerrit_user                       => 'jenkins',
      install_fortify                   => false,
      job_builder_configs               => [ 'fortify-scan.yaml',
                                              'tutorials.yaml',
                                              'publish-to-stackato.yaml',
                                              'puppet-checks.yaml'
                                            ],
      jenkins_solo                      => true,
    }->
    class { 'cdk_project::zuul':
      vhost_name                        => $node_vhost,
      gerrit_server                     => $gerrit_url,
      gerrit_user                       => 'jenkins',
      zuul_ssh_private_key              => $jenkins_private_key,
      ca_certs_db                       => $ca_certs_db,
      url_pattern                       => '',
      sysadmins                         => [],
      statsd_host                       => $graphite_url,
      zuul_url                          => "http://${node_vhost}/p",
    }->

    stackato_cli{'my-stackato-cli': }
  } else {
    notify{'Waiting until the jenkins user and gerrit server are ready..':}
  }
}
