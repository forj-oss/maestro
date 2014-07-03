#!/bin/bash

# Copyright 2013 OpenStack Foundation.
# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# Install pip using get-pip
EZ_SETUP_URL=https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py
PIP_GET_PIP_URL=https://raw.github.com/pypa/pip/master/contrib/get-pip.py

curl -O $EZ_SETUP_URL || wget $EZ_SETUP_URL
python ez_setup.py
curl -O $PIP_GET_PIP_URL || wget $PIP_GET_PIP_URL
python get-pip.py

# Install puppet version 2.7.x from puppetlabs.
# The repo and preferences files are also managed by puppet, so be sure
# to keep them in sync with this file.

if cat /etc/*release | grep -e "Fedora" &> /dev/null; then

    yum update -y

    # NOTE: we preinstall lsb_release to ensure facter sets lsbdistcodename
    yum install -y redhat-lsb-core git puppet

    gem install hiera hiera-puppet

    mkdir -p /etc/puppet/modules/
    ln -s /usr/local/share/gems/gems/hiera-puppet-* /etc/puppet/modules/

    # Puppet is expecting the command to be pip-python on Fedora
    ln -s /usr/bin/pip /usr/bin/pip-python

elif cat /etc/*release | grep -e "CentOS" -e "Red Hat" &> /dev/null; then
    rpm -qi epel-release &> /dev/null || rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-6.noarch.rpm

    cat > /etc/yum.repos.d/puppetlabs.repo <<"EOF"
[puppetlabs-products]
name=Puppet Labs Products El 6 - $basearch
baseurl=http://yum.puppetlabs.com/el/6/products/$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
exclude=puppet-2.8* puppet-2.9* puppet-3*
EOF

    yum update -y
    # NOTE: enable the optional-rpms channel (if not already enabled)
    # yum-config-manager --enable rhel-6-server-optional-rpms

    # NOTE: we preinstall lsb_release to ensure facter sets lsbdistcodename
    yum install -y redhat-lsb-core git puppet
else
    #defaults to Ubuntu
    # NB: keep in sync with openstack_project/files/00-puppet.pref
    cat > /etc/apt/preferences.d/00-puppet.pref <<EOF
Package: puppet puppet-common puppetmaster puppetmaster-common puppetmaster-passenger
Pin: version 2.7*
Pin-Priority: 501

Package: facter
Pin: version 1.*
Pin-Priority: 501
EOF

    lsbdistcodename=`lsb_release -c -s`
    puppet_deb=puppetlabs-release-${lsbdistcodename}.deb
    wget http://apt.puppetlabs.com/$puppet_deb -O $puppet_deb
    dpkg -i $puppet_deb
    rm $puppet_deb

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get --option 'Dpkg::Options::=--force-confold' \
        --assume-yes dist-upgrade
    DEBIAN_FRONTEND=noninteractive apt-get --option 'Dpkg::Options::=--force-confold' \
        --assume-yes install -y --force-yes puppet git rubygems
fi

# disable ec2 facters on openstack clouds
# on openstack clouds we have determined that bugs in puppet 2.7 and 
# network issues connecting to ec2 meta server service is cause hard puppet failures.
# we use well known macaddress comparision to determin if this is an openstack cloud.
# this is same method being used by facter 1.7.5
# This can be re-evaluated in puppet 3.4 implementation
# we can re-enable this through hiera configuration via puppetmaster.pp
# set the configuration to puppet::disable_ec2=false or export EC2_DISABLE=false for this script.
if [ $(ifconfig -a|egrep '(?:ether|HWaddr) ((\w{1,2}:){5,}\w{1,2})'|grep eth0 | awk '{print $5}'|egrep '^(02|[fF][aA]):16:3[eE]') ] ; then
  if [ -z "${EC2_DISABLE}" ] ; then
    export EC2_DISABLE=true
    echo "found openstack cloud, disable ec2 facters"
    echo "use hiera config puppet::disable_ec2=false to re-enable"
  fi
fi
if [ "${EC2_DISABLE}" = "true" ] ; then
  if [ -f /var/lib/gems/1.8/gems/facter-1.7.6/lib/facter/ec2.rb ] ; then
    mv /var/lib/gems/1.8/gems/facter-1.7.6/lib/facter/ec2.rb /var/lib/gems/1.8/gems/facter-1.7.6/lib/facter/ec2.rb.disable
  fi
  if [ -f /usr/lib/ruby/vendor_ruby/facter/ec2.rb ] ; then
    mv /usr/lib/ruby/vendor_ruby/facter/ec2.rb /usr/lib/ruby/vendor_ruby/facter/ec2.rb.disable
  fi
fi
