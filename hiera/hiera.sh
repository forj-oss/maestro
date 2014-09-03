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

# package requirements
puppet resource package build-essential ensure=present
puppet resource package make ensure=present
puppet resource package ruby1.8-dev ensure=present
puppet resource package libxml2-dev ensure=present
puppet resource package libxslt-dev ensure=present


#Install hiera using gems.
gem install --include-dependencies --no-rdoc --no-ri hiera

#TODO we only need one of the below installations, but as puppet is having issues we need to install hiera twice.
#Install hiera-puppet on systems without native packages.
ruby1.8 -S gem install --include-dependencies --no-rdoc --no-ri hiera-puppet

#Install hiera-puppet using puppet, this can be also installed with command but it was not created with the correct permissions.
puppet resource package hiera-puppet ensure=installed

# Create the folder for the hiera data
mkdir -p /etc/puppet/hieradata

echo "################# Hiera Installation done, step 1/2 ###################"

#install hiera-eyaml
ruby1.8 -S gem install --include-dependencies --no-rdoc --no-ri hiera-eyaml
ruby1.8 -S gem install --include-dependencies --no-rdoc --no-ri deep_merge
ruby1.8 -S gem install --include-dependencies --no-rdoc --no-ri json

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
eyaml createkeys

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
mysql_root_password='changeme'
eyaml encrypt -l 'mysql_password' -s $mysql_root_password | grep "mysql_password: ENC" >> $eyaml_file
eyaml encrypt -l 'mysql_root_password' -s $mysql_root_password | grep "mysql_root_password: ENC" >> $eyaml_file

eyaml encrypt -l 'maestro::app::mysql_root_password' -s $mysql_root_password | grep "maestro::app::mysql_root_password: ENC" >> $eyaml_file
eyaml encrypt -l 'maestro::app::mysql_password' -s '$Changeme01' | grep "maestro::app::mysql_password: ENC" >> $eyaml_file


echo "################# Hiera eyaml Installation done, step 2/2 done  ###################"