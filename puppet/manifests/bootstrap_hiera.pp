#
# Bootstrap the server to become a puppetmaster

node /.*(maestro|precise32).*/ {
  #
  # all nodes should meet these requirements.
  #
  # global's
  Exec { path => [
    '/bin/',
    '/sbin/',
    '/usr/bin/',
    '/usr/sbin/',
    '/usr/local/bin/'
    ]
  }

  include gardener
  require cdk_project::pip
  notice("openstack puppetmaster blueprint working for ${::fqdn}")

  class { 'hiera':
    data_class => 'runtime_project::hiera_setup',
  } ->
  # puppetmaster : 4505, 4506
  # salt         : 8139, 8140
  # dashboard    : 80, 443, 3000
  ::sysadmin_config::setup { 'setup puppetmaster and dashboard ports':
    iptables_public_tcp_ports => [4505, 4506, 8139, 8140, 80, 443, 3000, 8080],
    sysadmins                 => $sysadmins,
  }
}


