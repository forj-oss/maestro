#!/bin/bash

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
# Distro identification functions
#  note, can't rely on lsb_release for these as we're bare-bones and
#  it may not be installed yet)


function is_fedora {
    [ -f /usr/bin/yum ] && cat /etc/*release | grep -q -e "Fedora"
}

function is_rhel6 {
    [ -f /usr/bin/yum ] && \
        cat /etc/*release | grep -q -e "Red Hat" -e "CentOS" && \
        cat /etc/*release | grep -q 'release 6'
}

function is_rhel7 {
    [ -f /usr/bin/yum ] && \
        cat /etc/*release | grep -q -e "Red Hat" -e "CentOS" && \
        cat /etc/*release | grep -q 'release 7'
}

function is_ubuntu {
    [ -f /usr/bin/apt-get ]
}
#
# Distro specific puppet installs
#

function setup_hiera_rhel6 {
  puppet resource package gcc ensure=present
  puppet resource package gcc-c++ ensure=present
  puppet resource package kernel-devel ensure=present
  puppet resource package make ensure=present
  puppet resource package ruby-devel ensure=present
  puppet resource package rubygems ensure=present
  puppet resource package libxml2-devel ensure=present
  puppet resource package libxslt-devel ensure=present
  puppet resource package hiera ensure=installed
  #  puppet resource package hiera-puppet ensure=installed
  gem install --include-dependencies --no-rdoc --no-ri hiera-puppet

  }

function setup_hiera_rhel7 {
  puppet resource package gcc ensure=present
  puppet resource package gcc-c++ ensure=present
  puppet resource package kernel-devel ensure=present
  puppet resource package make ensure=present
  puppet resource package ruby-devel ensure=present
  puppet resource package rubygems ensure=present
  puppet resource package libxml2-devel ensure=present
  puppet resource package libxslt-devel ensure=present
  puppet resource package hiera ensure=installed
  #  puppet resource package hiera-puppet ensure=installed
  gem install --include-dependencies --no-rdoc --no-ri hiera-puppet

  }

function setup_hiera_ubuntu {
  # package requirements
  puppet resource package build-essential ensure=present
  puppet resource package make ensure=present
  puppet resource package ruby1.8-dev ensure=present
  puppet resource package rubygems ensure=present
  puppet resource package libxml2-dev ensure=present
  puppet resource package libxslt-dev ensure=present
  #Install hiera using gems.
  ruby1.8 -S gem install --include-dependencies --no-rdoc --no-ri hiera

  #TODO we only need one of the below installations, but as puppet is having issues we need to install hiera twice.
  #Install hiera-puppet on systems without native packages.
  ruby1.8 -S gem install --include-dependencies --no-rdoc --no-ri hiera-puppet

  #Install hiera-puppet using puppet, this can be also installed with command but it was not created with the correct permissions.
  puppet resource package hiera-puppet ensure=installed

}

function eyaml_bin {
  if [ -f /usr/local/bin/eyaml ] ; then
    /usr/local/bin/eyaml $@
  else
    /usr/bin/eyaml $@
  fi
}

# Create the folder for the hiera data
mkdir -p /etc/puppet/hieradata


if is_rhel6; then
    setup_hiera_rhel6
elif is_rhel7; then
    setup_hiera_rhel7
elif is_ubuntu; then
    setup_hiera_ubuntu
else
    echo "*** Can not setup hiera: distribution not recognized"
    exit 1
fi



echo "################# Hiera Installation done, step 1/2 ###################"

#install hiera-eyaml
if is_ubuntu; then
    # Required because last version (1.7.1) of highline package only works for ruby 1.9
    gem install --include-dependencies --no-rdoc --no-ri highline -v '~> 1.6.19'
    gem install --include-dependencies --no-rdoc --no-ri hiera-eyaml
    gem install --include-dependencies --no-rdoc --no-ri deep_merge
    gem install --include-dependencies --no-rdoc --no-ri json -v '~>1.7.5'
elif is_rhel6; then
    gem install --include-dependencies --no-rdoc --no-ri highline -v '~> 1.6.19'
    gem install --include-dependencies --no-rdoc --no-ri hiera-eyaml
    gem install --include-dependencies --no-rdoc --no-ri deep_merge
    gem install --include-dependencies --no-rdoc --no-ri json  -v '~>1.7.5'
elif is_rhel7; then
    gem install  highline -v '~> 1.6.19'
    gem install  hiera-eyaml
    gem install  deep_merge
    gem install  json  -v '~>1.7.5'
else
    echo "*** Can not setup hiera: distribution not recognized"
    exit 1
fi



#create location to store the public and private keys
mkdir -p /etc/puppet/secure
cd /etc/puppet/secure
if [ -f /etc/puppet/secure/keys/public_key.pkcs7.pem ] ; then
    cp /etc/puppet/secure/keys/public_key.pkcs7.pem /etc/puppet/secure/keys/public_key.pkcs7.pem.bak
    rm -f /etc/puppet/secure/keys/public_key.pkcs7.pem
fi
if [ -f /etc/puppet/secure/keys/private_key.pkcs7.pem ] ; then
    cp /etc/puppet/secure/keys/private_key.pkcs7.pem /etc/puppet/secure/keys/private_key.pkcs7.pem.bak
    rm -f /etc/puppet/secure/keys/private_key.pkcs7.pem
fi

#create keys
eyaml_bin createkeys

# set permissions to folders and keys
chown -R puppet:puppet /etc/puppet/secure/keys
chmod -R 0500 /etc/puppet/secure/keys
chmod 0400 /etc/puppet/secure/keys/*.pem
ls -lha /etc/puppet/secure/keys

#encript the site-params.yaml file
#eyaml encrypt -f /etc/puppet/hieradata/site-params.yaml
# create the site-params.eyaml
#cat <<EOF >/etc/puppet/hieradata/site-params.eyaml
#---
#mysql_password: 'changeme'
#mysql_root_password: 'changeme'
#EOF

eyaml_file="/etc/puppet/hieradata/common.eyaml"

#Add encrypted parameters
mysql_password=$(openssl rand -hex 10)
mysql_root_password=$(openssl rand -hex 10)
mysql_kitusr_password=$(openssl rand -hex 10)
eyaml_bin encrypt -l 'mysql_password' -s $mysql_password | grep "mysql_password: ENC" >> $eyaml_file
eyaml_bin encrypt -l 'mysql_root_password' -s $mysql_root_password | grep "mysql_root_password: ENC" >> $eyaml_file
eyaml_bin encrypt -l 'mysql_kitusr_password' -s $mysql_kitusr_password | grep "mysql_kitusr_password: ENC" >> $eyaml_file

rabbitmq_password='changeme'
eyaml_bin encrypt -l 'rabbit::password' -s $rabbitmq_password | grep "rabbit::password: ENC" >> $eyaml_file

ldap_password='changeme'
eyaml_bin encrypt -l 'ldap_config::rootpw' -s $ldap_password | grep "ldap_config::rootpw: ENC" >> $eyaml_file


echo "################# Hiera eyaml Installation done, step 2/2 done  ###################"
