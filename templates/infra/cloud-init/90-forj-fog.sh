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


# This script implements the fog credential file required by MAESTRO to create the instance of a blueprint.

function check_var
{
 if [ "$1" = "" ]
 then
    echo "$2. Script aborted."
    exit 1
 fi
}


# Protect sensible data not visible from any logs... Do not remove the next line with set +x.
set +x 

SCRIPT_PWD=$(dirname $0)

install -d -m 750 /opt/config/fog -o puppet -g puppet

HPCLOUD_PRIV="$(GetJson /meta-boot.js hpcloud_priv)"
COMPUTE_TENANT_NAME="$(GetJson /meta-boot.js tenant_name)" # Used for Compute
COMPUTE_OS_REGION="$(GetJson /meta-boot.js hpcloud_os_region)"
DNS_TENANT_ID="$(GetJson /meta-boot.js dns_tenantid)" # Used for DNS
DNS_ZONE="$(GetJson /meta-boot.js dns_zone)"

if [ "$HPCLOUD_PRIV" = "" ]
then
   echo "Unable to decrypt HPCloud private data. Missing 'hpcloud_priv' metadata. Script aborted."
   exit 1
fi
# This is an encoded 64 data. '=' is a pad unsupported by meta-data and removed before sending the data. We need to ensure pad is back in data
let PAD64=4-$(printf "$HPCLOUD_PRIV" | wc -c)%4
if [ $PAD64 -ne 4 ]
then # Missing pad.
   echo "Missing encoded 64 pad re-added..."
   PAD="$(echo "===" | cut -c1-$PAD64)"
   HPCLOUD_PRIV="$HPCLOUD_PRIV$PAD"
fi

eval "$(echo "$HPCLOUD_PRIV" | base64 -d | gunzip)"

# Default Compute parameters
COMPUTE_OS_AUTH_URL="https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/"

# Default DNS parameters
DNS_AUTH_URL="https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/"


###########################################################################################
# Section to build the fog file. It is composed by a section for compute and a section for DNS.

# Define Compute data ################

# Needs:
# HPCLOUD_OS_USER     - Provided by meta-data 'hpcloud_priv' encoded base64
# HPCLOUD_OS_KEY      - Provided by meta-data 'hpcloud_priv' encoded base64
# COMPUTE_OS_AUTH_URL - Provided by this script
# COMPUTE_TENANT_NAME - Provided by meta-data 'tenant_name'. Used by fog hp provider.
# COMPUTE_OS_REGION   - Provided by meta-data 'hpcloud_os_region'.

check_var "$HPCLOUD_OS_USER"     "Missing HPCLOUD_OS_USER. Check your metadata 'hpcloud_priv'."
check_var "$HPCLOUD_OS_KEY"      "Missing HPCLOUD_OS_KEY. Check your metadata 'hpcloud_priv'."
check_var "$COMPUTE_OS_REGION"   "Missing COMPUTE_OS_REGION. Check your metadata 'hpcloud_os_region'."
check_var "$COMPUTE_TENANT_NAME" "Missing TENANT_NAME. Check your metadata 'tenant_name'."
DEFAULT="
default:
  openstack_api_key: '${HPCLOUD_OS_KEY}'
  openstack_auth_url: ${COMPUTE_OS_AUTH_URL}tokens
  openstack_region: $COMPUTE_OS_REGION
  openstack_tenant: $COMPUTE_TENANT_NAME
  openstack_username: '${HPCLOUD_OS_USER}'"

# Define DNS data ######################

# Needs:
# DNS_KEY       - Provided by meta-data 'hpcloud_priv' encoded base64
# DNS_SECRET    - Provided by meta-data 'hpcloud_priv' encoded base64
# DNS_AUTH_URL  - Provided by this script
# DNS_TENANT_ID - Provided by meta-data 'dns_tenantid'
# DNS_ZONE      - Provided by meta-data 'dns_zone'.

check_var "$DNS_KEY"       "Missing DNS_KEY. Check your metadata 'hpcloud_priv'."
check_var "$DNS_SECRET"    "Missing DNS_SECRET. Check your metadata 'hpcloud_priv'."
check_var "$DNS_ZONE"      "Missing DNS_ZONE. Check your metadata 'dns_zone'."
check_var "$DNS_TENANT_ID" "Missing DNS_TENANT_ID. Check your metadata 'dns_tenantid'."

echo "$DEFAULT
dns:
  hp_access_key: '${DNS_KEY}'
  hp_secret_key: '${DNS_SECRET}'
  hp_auth_uri: $DNS_AUTH_URL
  hp_tenant_id: $DNS_TENANT_ID
  hp_avl_zone: $DNS_ZONE
  hp_account_id:
forj:
  provider: openstack 
 
# vim: syntax=yaml" > /opt/config/fog/cloud.fog

chown puppet:puppet /opt/config/fog/cloud.fog
echo "/opt/config/fog/cloud.fog created"
###########################################################################################

# vim: syntax=sh
