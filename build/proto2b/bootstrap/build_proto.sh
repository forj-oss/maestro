#!/bin/bash -x

function GetJson
{
 python -c "exec(\"import json\\njson_d=open('$1').read()\\ndata=json.loads(json_d)\\nprint(data['$2'])\")"
}

echo "################# BOOT-Ero Start step 1 #################"

set -x

locale-gen en_US

if [ -f /config/meta.js ]
then
   PREFIX=/config
fi

if [ ! -f $PREFIX/meta.js ]
then
   echo "Boot image invalid. Cannot go on!"
   exit 1
fi


_PUPPET_MASTER="$(GetJson $PREFIX/meta.js erosite)"
_PUPPET_MASTER_FQDN="${_PUPPET_MASTER}.$(GetJson $PREFIX/meta.js erodomain)"

sed -e "s/^certname.*=.*/certname = $_PUPPET_MASTER_FQDN/" /etc/puppet/puppet.conf --in-place
sed -e "s/^server.*=.*/server = $_PUPPET_MASTER_FQDN/" /etc/puppet/puppet.conf --in-place

service puppet stop

apt-get purge -yq python-pip

service puppet start

# ---------------- Code from original Miqui's simple boot file. The puppet file is generated from this file.

apt-get install -y git

git clone https://github.com/openstack-infra/config

bash ./config/install_puppet.sh

echo 'node default {
    
    notice("setup ${::fqdn}")

    $pkgs = [ "libtool", "curl", "wget", "bison" , "python-novaclient", "build-essential", "openssl",
    "unzip", "gcc", "make", "perl", "cpio" , "patch", "autoconf",
    "bzip2", "tcpdump", "strace", "python-paramiko", "libxslt-dev" ]
    
    package { $pkgs: ensure => present }
}' > build_proto.pp

puppet apply --modulepath=/etc/puppet/modules/:. build_proto.pp

# cleanup

#rm -rf ./config

mv /var/log/cloud-init.log /var/log/cloud-init.proto.log
rm -fr /var/lib/puppet/ssl
rm -f /meta.js
umount /config
rm -fr /config
exit 0
