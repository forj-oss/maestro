#TODO: create specs / test directory and move this.
#
# setup a wiki server
#
node default {
  include openstack_project::puppet_cron
  class { 'openstack_project::server':
    sysadmins => hiera('sysadmins'),
  }
}

# info about mediawiki:
#
# https://www.mediawiki.org/wiki/MediaWiki
#

node /.*(wiki|precise32).*/ {
  class { 'openstack_project::wiki':
    mysql_root_password     => hiera('wiki_db_password'),
    sysadmins               => hiera('sysadmins'),
    ssl_cert_file_contents  => hiera('wiki_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('wiki_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('wiki_ssl_chain_file_contents'),
  }
}


# vim:sw=2:ts=2:expandtab:textwidth=79
