#TODO: create specs / test directory and move this.
node /.*(review|precise32).*/  {

  if $hostname == 'precise32' {
    $paste_server = 'localhost'
  } else {
    $paste_server = inline_template('<% if defined?(@ec2_public_ipv4) %><%= @ec2_public_ipv4 %><% elsif defined?(@ipaddress_eth0)%><%= @ipaddress_eth0 %><% else %><%= @fqdn %><% end %>')
  }

  $paste_vhost = $paste_server

  class { 'cdk_project::paste':
    sysadmins  => [],
    vhost_name => $paste_vhost,
    site_name  => 'cdkdev',
  }
}
