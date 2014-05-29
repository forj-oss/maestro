
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

#TODO: Defect #166: when implemented this code should be removed
[ ! -d /var/lib/python-install ] && mkdir -p /var/lib/python-install
 $(cd /var/lib/python-install; wget https://raw.github.com/pypa/pip/8575e0c16424bcc9866baa0f9f779f1b524fbc20/contrib/get-pip.py; chmod +x ./get-pip.py)
