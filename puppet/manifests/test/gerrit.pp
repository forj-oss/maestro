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
# This manifest file is currently working in vagrant orchestrator box.
# we will port this later to work on a deployed system.
#TODO: create specs / test directory and move this.
$mysql_password = 'changeme'
$mysql_root_password = 'changeme'


node /.*(review|precise32).*/  {

#
# all nodes should meet these requirements.
#
  include cdk_project::pip
  if !defined(Class['pip::python2']) {
    include pip::python2
  }

# custom settings for local vagrant testing

  $override_vhost = true
  # this configuration should be different if we are registered with a dns
  # name.  For now we use ipv4, otherwise we would use fqdn

  # system config
  if str2bool($::vagrant_guest) == true {
    notice( 'Using vagrant configuration for local testing.' )
    $def_container_heaplimit = '112m'
    $gerrit_vhost            = 'precise32'
    $gerrit_server           = 'localhost'
    $gerrit_server_url       = "https://${gerrit_server}:8443/"
  } else {
    # large systems should be 8gb
    # TODO: we should have a class that defines systems

    $def_container_heaplimit = '900m'
    if str2bool($override_vhost) == true {
      $gerrit_server = inline_template('<% if defined?(@ec2_public_ipv4) %><%= @ec2_public_ipv4 %><% elsif defined?(@ipaddress_eth0)%><%= @ipaddress_eth0 %><% else %><%= @fqdn %><% end %>')
      $gerrit_vhost      = $gerrit_server
      $gerrit_server_url = "https://${gerrit_server}/"
    } else {
      $gerrit_server     = $fqdn
      $gerrit_vhost      = $gerrit_server
      $gerrit_server_url = "https://${gerrit_server}/"
    }
  }

  ::sysadmin_config::setup { 'setup gerrit & salt ports':
    iptables_public_tcp_ports => [80, 443,8139, 8140, 29418, 8080],
    sysadmins                 => [],
  } ->

  ::sysadmin_config::swap { '512': } ->

  notify{ "Openstack gerrit blueprint working for ${gerrit_server}": } ->

  class { 'cdk_project::gerrit':
    serveradmin                     => "webmaster@${::domain}",
    ssl_cert_file                   => "/etc/ssl/certs/${::fqdn}.pem",
    ssl_key_file                    => "/etc/ssl/private/${::fqdn}.key",
    ssl_chain_file                  => '/etc/ssl/certs/intermediate.pem',

    # these will be automatically created if we pass them in empty.
    ssl_cert_file_contents          => '',
    ssl_key_file_contents           => '',
    ssl_chain_file_contents         => '',

    # Working with a test server, generate some keys
    ssh_dsa_key_contents            => '',
    ssh_dsa_pubkey_contents         => '',
    ssh_rsa_key_contents            => '',
    ssh_rsa_pubkey_contents         => '',
    ssh_project_rsa_key_contents    => '',
    ssh_project_rsa_pubkey_contents => '',
    email                           => "review@${::domain}",
    # 1 + 100 + 9 + 2 + 2 + 25 = 139(rounded up)
    database_poollimit              => '150',
    container_heaplimit             => $def_container_heaplimit,
    core_packedgitopenfiles         => '4096',
    core_packedgitlimit             => '400m',
    core_packedgitwindowsize        => '16k',
    sshd_threads                    => '100',
    httpd_maxwait                   => '5000min',
    war                             => 'http://tarballs.openstack.org/ci/gerrit-2.4.4-14-gab7f4c1.war',
    contactstore                    => false,
    contactstore_appsec             => '',
    contactstore_pubkey             => '',
    contactstore_url                => 'http://www.openstack.org/verify/member/',
    script_user                     => 'gerrit2',
    script_key_file                 => '/home/gerrit2/.ssh/gerrit2',
    script_logging_conf             => '/home/gerrit2/.sync_logging.conf',
    projects_file                   => 'review.projects.yaml.erb',
    github_username                 => "${::domain}-gerrit",
    github_oauth_token              => '',
    github_project_username         => '',
    github_project_password         => '',
    mysql_password                  => $mysql_password,
    mysql_root_password             => $mysql_root_password,
    trivial_rebase_role_id          => "trivial-rebase@review.${::domain}",
    #TODO needs autogeneration at some point
    email_private_key               => 'FU7D198KY5xEx55/+YA1piHcfhwy/fo8sZk=',
    sysadmins                       => '',
    swift_username                  => '',
    swift_password                  => '',
    replication                     => [
      {
        name                 => 'local',
        url                  => 'file:///var/lib/git/',
        replicationDelay     => '0',
        threads              => '4',
        mirror               => true,
      }
    ],
    canonicalweburl                 => $gerrit_server_url,
    vhost_name                      => $gerrit_vhost,
    ip_vhost_name                   => $gerrit_server,
    runtime_module                  => 'runtime_project',
    override_vhost                  => $override_vhost,
    demo_enabled                    => true,
    }
}
