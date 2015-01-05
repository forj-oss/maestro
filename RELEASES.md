Introduction
=============

Here we will atempt to document developer release notes that can assist
with upgrades from older versions of forj.  Note, these notes may or may not
work depending on your current release.

Upgrading after 1/5/2015
=========================
https://review.forj.io/#/c/2014/ Introduces a new ldap service that will be leveraged for central authentication on future blueprints.
  - remove old ldap
  ```shell
  sudo apt-get purge slapd
  ```
  - pull latest code for maestro and blueprint, example redstone
  ```shell
  cd /opt/config/production/git/maestro
  git pull

  # pull the latest blueprint for your instance, ie; for redstone
  cd /opt/config/production/git/redstone
  git pull
  ```
  - install new passwords for ldap_password, login to maestro as root.
  ```shell
  cd /etc/puppet/secure
  ldap_password='changeme'  # pick a better password
  eyaml_file="/etc/puppet/hieradata/common.eyaml"
  /usr/local/bin/eyaml encrypt -l 'ldap_config::rootpw' -s $ldap_password | grep "ldap_config::rootpw: ENC" >> $eyaml_file
  ```
  - install latest puppet modules
  ```shell
  cd /opt/config/production/git/maestro/puppet
  bash ./install_module.sh
  cd /opt/config/production/git/redstone/puppet # or your blueprint folder
  bash ./install_module.sh
  ```
  - enabling the service requires a new maestro.yaml configuration.
  ```shell
  # run puppet hiera function
  environment=production
  export environment
  PUPPET_MODULE_PATH=$(eval echo $(grep modulepath /etc/puppet/puppet.conf |awk -F= '{print $2}'))
  export PUPPET_MODULE_PATH
  puppet apply --modulepath=$PUPPET_MODULE_PATH -e "include hiera"
  ```
  - re-run puppet manifest
  ```shell
  sudo -i puppet agent -t
  ```
