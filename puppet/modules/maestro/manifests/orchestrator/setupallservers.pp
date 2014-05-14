# == maestro::setupallservers
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
#
# create all maestro instances
class maestro::orchestrator::setupallservers(
    $environment     = 'production',
    $nodes           = ['review'],
    $instance        = undef,
    $instance_domain = $domain,
    $ssh_gen_keys    = ['jenkins']
)
{
  debug('setting up all the servers')

  # we need an interger based serial number we can start our certificates with.
  # fixing (Error code: sec_error_reused_issuer_and_serial)
  # this allwos for 10k servers per kit before colliding, lets hope large
  # serial numbers hold up
  debug("using instance ${instance}")
  if $instance == undef
  {
    fail('we need an instance id to setup servers.  unable to continue.')
  }
  $instance_serial_start = inline_template('<% i = @instance.to_i(36) + 10000  %><%= i.to_s.hex.to_s.length.even? ? i.to_s.hex.to_s : \'0\' + i.to_s.hex.to_s %>')
  debug("instance_serial_start = ${instance_serial_start}")

  $eroip = inline_template('<% if defined?(@helion_public_ipv4) %><%= @helion_public_ipv4 %><% elsif defined?(@ec2_public_ipv4)%><%= @ec2_public_ipv4 %><% else %><%= @fqdn %><% end %>')

  # list all the servers we will create here
  $metadata = "erosite=${::hostname},erodomain=${instance_domain},eroip=${eroip},cdkdomain=${instance_domain},cdksite=<%= server_name %>"
  cacerts::cacerts_createssh { 'init':
        domain       => $instance_domain,
        environment  => $environment,
        serial_init  => $instance_serial_start,
        install_only => true,
  } ->
  cacerts::sshgenkeys{$ssh_gen_keys:  do_cacertsdb=>true}

  if ( $maestro::network_name != undef and $maestro::network_name != '' )
  { # new format
    debug("using network_name => ${maestro::network_name}")
    class { 'gardener::params':
        image_name        => $maestro::image_name,
        flavor_name       => $maestro::flavor_name,
        key_name          => $maestro::key_name,
        security_groups   => $maestro::security_groups,
        network_name      => $maestro::network_name,
        template_metadata => $metadata,
        require           => Cacerts::Sshgenkeys[$ssh_gen_keys],
    }
  } else
  { # old
    warning('network_name not specified, 13.5 installations now require a network_name specification')
    class { 'gardener::params':
        image_name        => $maestro::image_name,
        flavor_name       => $maestro::flavor_name,
        key_name          => $maestro::key_name,
        security_groups   => $maestro::security_groups,
        template_metadata => $metadata,
        require           => Cacerts::Sshgenkeys[$ssh_gen_keys],
    }
  }

  maestro::orchestrator::gencerts { $nodes:
        instance_id => $instance,
        domain      => $maestro::instance_domain,
        serial_init => $instance_serial_start,
        require     => Class['gardener::params'],
  } ->
  class { 'puppet::autosign':
    nodes => join_arrpattern('%a.%s', $nodes, $instance_domain)
  }
  # attempt to build in a delay so we don't get
  # puppet auto-registration errors.
  class { 'gardener::server_up':
    nodes           => $nodes,
    instance_id     => $instance,
    instance_domain => $instance_domain,
    server_delay    => 20,
  } ->
# Disabled DNS so we can promote to stable, re-enable after we solve bugs
#  class {'maestro::orchestrator::managedns':
#    ensure           => present,
#    instance_id      => $instance,
#    zone             => $maestro::instance_domain,
#  } ->
  notify { 'maestro::orchestrator::setupallservers: completed bootstrap':
        message => join(["************ created servers  **********
                  instance    = ${instance}
                  domain      = ${maestro::instance_domain}
                  environment = ${environment}
              *************************************************" ]),
  }

}
