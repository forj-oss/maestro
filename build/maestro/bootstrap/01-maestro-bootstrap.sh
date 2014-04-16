# Identify branch to use for GIT clones

GITBRANCH="$(GetJson /meta-boot.js gitbranch)"
if [ "$GITBRANCH" != "" ]
then
    GITBRANCH_FLAG="-b $GITBRANCH"
fi

# Get maestro repository for bootstrap

git config --global http.sslVerify false # Required because FORJ ssl is selfsigned.
mkdir -p /opt/config/production/git
chmod 2775 /opt/config/production/git
_CWD=$(pwd)
cd /opt/config/production/git

MAESTRO_LINK="$(GetJson /meta-boot.js maestrolink)"
GitLinkCheck $MAESTRO_LINK
if [ ! $? -eq 0 ] 
then
   echo "INFO: using default MAESTRO git url"
   MAESTRO_LINK="https://15.185.237.61/p/forj-oss/maestro"
fi

git clone $GITBRANCH_FLAG $MAESTRO_LINK maestro
cd maestro
git config core.autocrlf false

ln -s /opt/config/production/git/maestro/puppet /opt/config/production
