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

function GetJson
{
 python -c "
import json
import os.path
import sys
 
if os.path.isfile('$1'):
   json_d=open('$1').read()
   data=json.loads(json_d)
   if '$2' in data.keys():
      print(data['$2'])
      print >> sys.stderr, '$1 - Found: $2 = \"'+data['$2']+'\"'
   else:
      print '$3'
      print >> sys.stderr, 'Key \"$2\" not found. Default value to \"$3\"'
else:
   print '$3'
   print >> sys.stderr, 'Warning! File \"$1\" was not found. Default value to \"$3\"'
"
}

# Install log requirement.
apt-get install gawk -y

exec 6>&1 > >( awk '{ POUT=sprintf("%s - %s",strftime("%F %X %Z",systime()),$0);
                 print POUT;
                 print POUT >> "/var/log/cloud-init.log"
                 fflush("");
                }') 2>&1

echo "################# 1st sequence : user_data BOOTHOOK Start #################"

PREFIX=/

# make sure we have a valid location for the meta.js file
# and try to get info from openstack structures if available
if [ ! -f $PREFIX/meta.js ]
then
  if [ ! -d /config ]
  then
    mkdir -p /config
    mount /dev/vdc /config
    if [ -f /config/meta.js ]
    then
      PREFIX=/config
    else
      mount /dev/sr0 /config
      if [ -f  /config/openstack/latest/meta_data.json ]
      then
        _meta_data="$(GetJson /config/openstack/latest/meta_data.json meta)"
        if [ -n "$_meta_data" ]
        then
          PREFIX=/
          echo "$_meta_data" > $PREFIX/meta.js
          sed -e "s/u'/\"/g" $PREFIX/meta.js --in-place
          sed -e "s/'/\"/g" $PREFIX/meta.js --in-place
        fi
      fi
    fi
  fi
fi

#if metadata does not exist grab it form the Upstream provided data ({metadata-json} is replaced by upstream code (build.sh))
if [ ! -f $PREFIX/meta.js ] 
then
  echo '${metadata-json}' > /meta-boot.js
  echo "WARNING! /meta.js not found. Getting info from user_data"
fi

#try to validate that the content is OK, as last fallback hardcode the data
_test_data="$(GetJson $PREFIX/meta.js cdksite)"
if [ "$_test_data" == "" ]
then
  echo '{"cdkdomain":"forj.io","cdksite":"maestro.hard","erosite":"maestro.hard","erodomain":"forj.io","eroip": "127.0.0.1", "gitlink": "ssh://review/forj-oss/maestro","instanceid": "hard", "network_name": "private"}' > $PREFIX/meta.js
  echo "WARNING! /config/meta.js not found. HARDCODING DATA"
fi

cp $PREFIX/meta.js /meta-boot.js
chmod 644 /meta-boot.js

cat $PREFIX/meta.js

if [ ! -f $PREFIX/meta.js ]
then
   echo "Boot image invalid. Cannot go on!"
   exit 1
fi

# Proxy management
_PROXY="$(GetJson $PREFIX/meta.js webproxy)"
if [ -n "$_PROXY" ] && [ "$(grep -i http_proxy /etc/environment)" = "" ]
then
    set -x
    echo "export HTTP_PROXY=$_PROXY
export http_proxy=$_PROXY
export HTTPS_PROXY=$_PROXY
export https_proxy=$_PROXY
export FTP_PROXY=$_PROXY
export no_proxy=localhost,127.0.0.1,10.0.0.1,169.254.169.254" >> /etc/environment
    source /etc/environment
    echo "Acquire::http::proxy \"$_PROXY\";
Acquire::https::proxy \"$_PROXY\";
Acquire::ftp::proxy \"$_PROXY\";"  >/etc/apt/apt.conf
    set +x
fi	
# hostname, and domain settings have to be fixed to make puppet master/agent running together.

# Loading Metadata (before debug mode to limit unwanted output...)
_SITE="$(GetJson $PREFIX/meta.js cdksite)"
_DOMAIN="$(GetJson $PREFIX/meta.js cdkdomain)"
_PUPPET_MASTER_IP="$(GetJson $PREFIX/meta.js eroip)"
_PUPPET_MASTER="$(GetJson $PREFIX/meta.js erosite)"
_PUPPET_DOMAIN="$(GetJson $PREFIX/meta.js erodomain)"
#APT_MIRROR="$(GetJson $PREFIX/meta.js apt-mirror | sed 's/\//\\\//g') "

set -x
_FQDN=$_SITE.$_DOMAIN
_HOSTNAME=$(echo $_FQDN | awk -F'.' '{print $1}')

echo "$_FQDN" > /etc/hostname

cat /etc/hosts| grep "^127.0.0.1 ${_FQDN} ${_HOSTNAME}" > /dev/null 2<&1
if [ ! $? -eq 0 ]; then
   HOSTSTR=$(echo "127.0.0.1 ${_FQDN} ${_HOSTNAME}")
   bash -c 'echo '"$HOSTSTR"'>> /etc/hosts'
fi
hostname -b -F /etc/hostname


# maestro 	to /etc/hosts

_PUPPET_MASTER_FQDN=$_PUPPET_MASTER.$_PUPPET_DOMAIN
_PUPPET_MASTER_HOSTNAME=$(echo $_PUPPET_MASTER | awk -F'.' '{print $1}')

if [ "$(grep "^$_PUPPET_MASTER_IP" /etc/hosts)" = "" ]; then
   HOSTSTR=$(echo "$_PUPPET_MASTER_IP $_PUPPET_MASTER_FQDN $_PUPPET_MASTER_HOSTNAME salt")
   bash -c 'echo '"$HOSTSTR"'>> /etc/hosts'
fi
# remove the ability from dhclient to update doamin and search parameters
cp /etc/dhcp/dhclient.conf /etc/dhcp/dhclient.conf.bak
sed -e "s/domain-name, domain-name-servers, domain-search, host-name,/domain-name-servers,/" /etc/dhcp/dhclient.conf --in-place


#if [ -n "$APT_MIRROR" ]
#then
#   sed --in-place=.bak 's/^deb .*archive\.ubuntu\.com\/ubuntu/deb '"$APT_MIRROR"'/g' /etc/apt/sources.list
  sed -i -e \
            's,^archive.ubuntu.com/ubuntu,nova.clouds.archive.ubuntu.com/ubuntu,g'  \
             /etc/apt/sources.list 
#fi
# We want to make sure we use the ubuntu repo for passenger
# otherwise we run into compatability issues with puppetmaster-passenger and others.
# TODO: need to move this into puppet
[ -f /etc/apt/sources.list.d/passenger.list ] && rm -f /etc/apt/sources.list.d/passenger.list

apt-get -qy update
apt-get -qy upgrade
set +x
echo "################# 1st sequence : user_data BOOTHOOK ended  #################"
exec 1>&6 2>&1
