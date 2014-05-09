# Configure Openstack config from a freezed version maintained by FORJ team.

echo "host jenkins.cdkdev.org
     StrictHostKeyChecking=no" >> ~/.ssh/config

export HOME=/root
# Uses local stable resource instead of internet one. See ubuntu@jenkins.cdkdev.org

cd /opt/config/production/git
git clone $GITBRANCH_FLAG http://jenkins.cdkdev.org:82/ubuntu/config.git
cd config
git config core.autocrlf false
