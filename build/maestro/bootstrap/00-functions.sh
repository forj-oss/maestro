function GetJson
{
 python -c "exec(\"import json\\njson_d=open('$1').read()\\ndata=json.loads(json_d)\\nprint(data['$2'])\")"
}

# make sure that the passed in gitlink is a valid git repository url
function GitLinkCheck
{
   _LINK=$1
   if [ "$_LINK" = "" ] || [ "$_LINK" = "default" ] ; then
     # this is a default git url, return non-zero so the caller knows.
     return 2
   fi
   if [ "$(echo $_LINK | grep '://')" = "" ]
   then # Check scp link provided
      if [ "$(echo $_LINK | grep -ie '^.*:[a-z].*$')" = "" ]
      then
           echo "ERROR: $_LINK is not a scp valid format."
           return 1 
      else
           return 0
      fi
   else
      # validate we got a valid git URL
      _LINK_PROTOCOL=$(echo $_LINK | awk -F'://' '{printf $1}')
      if   [ "$_LINK_PROTOCOL" = "ssh" ]   ||
           [ "$_LINK_PROTOCOL" = "http" ]  ||
           [ "$_LINK_PROTOCOL" = "https" ] ||
           [ "$_LINK_PROTOCOL" = "git" ]   ||
           [ "$_LINK_PROTOCOL" = "file" ]  ||
           [ "$_LINK_PROTOCOL" = "SSH" ]   ||
           [ "$_LINK_PROTOCOL" = "HTTP" ]  ||
           [ "$_LINK_PROTOCOL" = "HTTPS" ] ||
           [ "$_LINK_PROTOCOL" = "GIT" ]   ||
           [ "$_LINK_PROTOCOL" = "FILE" ]  ; then
           return 0
       else
           echo "ERROR: $_LINK does not have a valid protocol for git"
           return 1 
       fi
   fi
}

exec 6>&1 > >( awk '{ POUT=sprintf("%s - %s",strftime("%F %X %Z",systime()),$0);
                 print POUT;
                 print POUT >> "/var/log/cloud-init.log";
                 fflush();
               }') 2>&1

echo "################# BOOT-Ero Start step 1 #################"

set -x

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


. /etc/environment
_PROXY="$(GetJson /meta-boot.js webproxy)"

apt-get purge -yq python-pip

export HOME=/root
