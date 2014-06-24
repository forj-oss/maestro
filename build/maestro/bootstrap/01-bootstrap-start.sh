# Setting log to /var/log/cloud-init.log
exec 6>&1 > >( awk '{ POUT=sprintf("%s - %s",strftime("%F %X %Z",systime()),$0);
                 print POUT;
                 print POUT >> "/var/log/cloud-init.log";
                 fflush("");
               }') 2>&1

echo "################# 1st sequence : user_data Maestro boot #################"

locale-gen en_US
# TODO: find if we can source meta.js values from facter since we
#  have all meta.js in facters now.
if [ -f /config/meta.js ]
then
   PREFIX=/config
fi

if [ ! -f $PREFIX/meta.js ]
then
   echo "Boot image invalid. Cannot go on!"
   exit 1
fi

declare -A TEST_BOX_REPOS
Load_test-box_repos # Loading test-box information for external bootstrapping (development)

. /etc/environment
_PROXY="$(GetJson /meta-boot.js webproxy)"

apt-get purge -yq python-pip

export HOME=/root
