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

# This boot script implements a CA certificate installation to your server.
#
# It requires metadata 'CA_ROOT_CERT' => relpath/file_name
# If set, it communicates with forj cli to send the file
# to /tmp
#
# As soon as the file exists and a flag file exists,
# the script will install it to:
#
# ubuntu:
#   /usr/share/ca-certificates
#   and execute `update-ca-certificates`
#
# redhat:
#   /etc/pki/ca-trust
#   and execute `update-ca-trust extract`

if [ -f "$INIT_FUNCTIONS" ]
then
   source $INIT_FUNCTIONS
else
   echo "Unable to load 'INIT_FUNCTIONS' ($INIT_FUNCTIONS). Script aborted."
   exit 1
fi

function file_where_to_install
{
   INSTALLED_FILE="$1"
   case  "$(GetOs)" in
     Ubuntu|Debian)
       echo "/usr/share/ca-certificates/$INSTALLED_FILE"
       ;;
     CentOS|'CentOS Linux'|RedHat|Fedora)
       echo "/etc/pki/ca-trust/$INSTALLED_FILE"
       ;;
      *)
       echo "/usr/share/ca-certificates/$INSTALLED_FILE"
       ;;
   esac
}

function file_update
{
   case  "$(GetOs)" in
     Ubuntu|Debian)
         install -v -D $1 $2
         echo "Adding $2 in /etc/ca-certificates.conf"
         echo "$3" >> /etc/ca-certificates.conf
         update-ca-certificates
       ;;
     CentOS|'CentOS Linux'|RedHat|Fedora)
       install -v -D $1 $2
       update-ca-trust extract
       ;;
      *)
       echo "Nothing done for '$(GetOs)'"
       ;;
   esac
}


CA_ROOT_CERT="$(GetJson /meta-boot.js CA_ROOT_CERT)"

if [ "$CA_ROOT_CERT" = "" ]
then
  echo "No root certificate to install."
  exit
fi

FILENAME=$(basename $CA_ROOT_CERT)
FILE_PATH=$(dirname $CA_ROOT_CERT)
DEST_FILE="$(file_where_to_install $CA_ROOT_CERT)"

if [ -f $DEST_FILE ]
then
   echo "Certificate file already installed. ignored."
   exit
fi

echo "forj-cli: ca-root-cert=${CA_ROOT_CERT}"
echo "build.sh:"
echo "Waiting for the orchestrator to send the certificate file."
echo "Maestro will wait until /tmp/${FILENAME}.done and /tmp/${FILENAME} are found."

while [ ! -f /tmp/${FILENAME}.done ] || [ ! -f /tmp/${FILENAME} ]
do
   sleep 5
done

echo "The certificate file has been received. Updating the OS."

file_update /tmp/${FILENAME} $DEST_FILE $CA_ROOT_CERT
