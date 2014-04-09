#
# This manifest file is currently working in vagrant orchestrator box.
# we will port this later to work on a deployed system.

#
# Setup host so that we can deal with vagrant configs and ip based configs
# this section still requires some work
# TODO: need to figure out if this should be global of not.

if str2bool($::vagrant_guest) == true {
  $node_server = 'localhost'
} else {
  $node_server = inline_template('<% if defined?(@ec2_public_ipv4) %><%= @ec2_public_ipv4 %><% elsif defined?(@ipaddress_eth0)%><%= @ipaddress_eth0 %><% else %><%= @fqdn %><% end %>')
}

$node_vhost = $node_server
$sysadmins = []

# implements hiera_data installations
node default {
    # global's
  Exec { path => [
    '/bin/',
    '/sbin/',
    '/usr/bin/',
    '/usr/sbin/',
    '/usr/local/bin/'
    ]
  }
  hiera_include('classes')
}

node /^review.*/ inherits default {

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
  # name.   For now we use ipv4, otherwise we would use fqdn

  # system config
  if str2bool($::vagrant_guest) == true {
    notice( 'Using vagrant configuration for local testing' )
    $def_container_heaplimit = '112m'
    $gerrit_vhost      = 'precise32'
    $gerrit_server     = $node_server
    $gerrit_server_url = "https://${gerrit_server}:8443/"
  } else {
    # large systems should be 8gb
    # TODO: we should have a class that defines systems
    $def_container_heaplimit = '900m'
    if $override_vhost {
      $gerrit_server     = $node_server
      $gerrit_vhost      = $gerrit_server
      $gerrit_server_url = "https://${gerrit_server}/"
    } else {
      $gerrit_server     = $fqdn
      $gerrit_vhost      = $gerrit_server
      $gerrit_server_url = "https://${gerrit_server}/"
    }
  }

  ::sysadmin_config::setup { 'setup gerrit ports':
      iptables_public_tcp_ports  => [80, 443, 8139, 8140, 29418, 8080],
      sysadmins                  => $sysadmins,
  } ->
  ::sysadmin_config::swap { '512':} ->

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
    github_username                 => '',  # "${::domain}-gerrit",
    github_oauth_token              => '',
    github_project_username         => '',
    github_project_password         => '',
    mysql_password                  => hiera('mysql_password'),
    mysql_root_password             => hiera('mysql_root_password'),
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
    require                         => Class['cdk_project::pip'],
    demo_enabled                    => true,
    buglinks_enabled                => true,
  }
}

#
# This manifest file is currently working in vagrant orchestrator box.
# we will port this later to work on a deployed system.

node /^maestro.*/ inherits default {

  # moved up sysadmin config due to integration of dashboard and maestro components
  # main app for this server, the controller ui for cdk
  notify{ 'maestro ui box execution': } ->
  ::sysadmin_config::setup { 'setup puppetmaster and dashboard ports':
      iptables_public_tcp_ports => [4505, 4506, 8139, 8140, 80, 443, 3000, 8080],
      sysadmins                 => $sysadmins,
  } ->
  ::sysadmin_config::swap { '512':}
}

#
# we need a utilities server until we fix puppet master bug that prevents server restart, so we can consilidate
node /^util.*/ inherits default {

  $zuul_url = read_json('zuul','tool_url',$::json_config_location,false)
  if $zuul_url != '' and $zuul_url != '#'
  {
    $statsd_hosts = [$zuul_url]
    $rules = regsubst ($statsd_hosts, '^(.*)$', '-m udp -p udp -s \1 --dport 8125 -j ACCEPT')
  }
  else
  {
    $rules = ''
  }
  ::sysadmin_config::setup { 'setup util node ports':
    iptables_public_tcp_ports => [22, 80, 443, 8080, 8081, 8125, 2003, 8080],
    iptables_rules4           => $rules,
    sysadmins                 => $sysadmins,
  }
}

#
# this is the jenkins/zuul server
node /^ci.*/ inherits default {

  $gerrit_user = 'jenkins'
  #TODO Read graphite_url from graphite not pastebin
  $graphite_url = read_json('graphite','tool_url',$::json_config_location,true)
  $ca_certs_db = '/opt/config/cacerts'
  $jenkins_private_key = cacerts_getkey(join([$ca_certs_db , '/ssh_keys/jenkins']))

  #last parameter is a flag to get the url as ip format only or include their
  # prefix ex http:// or https://
  $gerrit_url = read_json('gerrit','tool_url',$::json_config_location,true)
    if ( $jenkins_private_key != '' )  and ( $gerrit_url != '') {
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
        gerrit_user                       => $gerrit_user,
        install_fortify                   => false,
        job_builder_configs               => [  'config-layout.yaml',
                                                'fortify-scan.yaml',
                                                'tutorials.yaml',
                                                'publish-to-stackato.yaml',
                                                'puppet-checks.yaml'
                                              ],
        jenkins_solo                      => true,
      }->
      class { 'cdk_project::zuul':
        vhost_name                        => $node_vhost,
        gerrit_server                     => $gerrit_url,
        gerrit_user                       => $gerrit_user,
        zuul_ssh_private_key              => $jenkins_private_key,
        ca_certs_db                       => $ca_certs_db,
        url_pattern                       => '',
        sysadmins                         => [],
        statsd_host                       => $graphite_url,
        replication_targets               => [
          {
            name => 'url1',
            url  => "ssh://${gerrit_user}@${gerrit_url}:29418/"
          }
        ],
        zuul_url                          => "http://${node_vhost}/p",
        zuul_revision                     => '951d8f366ce68238e2988aadd913b2d12656bbb3',
      }->
      stackato_cli{'my-stackato-cli':
      }
    }
    else
    {
      notify{'Waiting to install until the jenkins user credentials and gerrit server are ready..':}
    }
}

node /^wiki.*/ inherits default {

#
# all nodes should meet these requirements.
#
  class{'cdk_project::pip':} ->
  class { 'openstack_project::wiki':
    mysql_root_password     => hiera('wiki_db_password'),
    sysadmins               => hiera('sysadmins'),
    ssl_cert_file_contents  => hiera('wiki_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('wiki_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('wiki_ssl_chain_file_contents'),
  }
}
