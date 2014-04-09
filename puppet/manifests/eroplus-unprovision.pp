#
# == maestro unprovision
# Copyright 2012 Hewlett-Packard Development Company, L.P
#
# This manifest file is currently working in vagrant orchestrator box.

if str2bool($::vagrant_guest) == true {
  $node_server = 'localhost'
} else {
  $node_server = inline_template('<% if defined?(@ec2_public_ipv4) %><%= @ec2_public_ipv4 %><% elsif defined?(@ipaddress_eth0)%><%= @ipaddress_eth0 %><% else %><%= @fqdn %><% end %>')
}

$node_vhost = $node_server

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

  # TODO check if calculates or from where gets the values that
  # I need to retrieve and use for the instance deletion.
  if empty($instance_id) {
    $tinst = split($hostname, '[-]')
    if $tinst[0] == $hostname {
      # the hostname does not contain a instance part
      $tdinst = split($fqdn, '[.]')
      if empty($tdinst[1]) {
        # the domain does not contain a instance part
        $instance_id = '42'
      } else {
        $instance_id = $tdinst[1]
      }
    } else {
      $instance_id = $tinst[0]
    }
  }


  notify{ "${hostname} - maestro unprovisionning kit '${instance_id}' ...": } ->
  pinas { "${hostname} - Destroying":
    ensure       => absent,
    instance_id  => $instance_id,
    nodes        => [
      'review',
      'util',
      'ci'
      ],
    do_parallel  => false,
  }
}
