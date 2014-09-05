forj/gardener
=====================

Manage cloud things for forj blueprints with puppet.


## Usage ##
   For examples on usage see manifests/tests

## Install ##

   include gardener

   The maestor class will use this module to cordinate the creation
   and management of nodes defined by the blueprint in hieradata.
   See maestro::orchestrator class for more details.

## Features ##

  - class for creating / destroying list of static nodes (server_up, server_destroy)
  - type for managing those nodes: pinas
  - various parsers for compute public and private ip lookup
  - helper functions for converting metadata from json to hash and strings
  - domain record lookup and management
  - configured to work with hiera
  - support for openstack 13.5, deprecation for 12.12 will come next.
  - usage of unix_cli objects

## WIP ##
  - object storage

## Planned ##
  - attached storage
  - more providers (AWS, rackspace)

## Intended Audience ##
  users of forj blueprints

## Testing ##
  setup your environment for testing:
- basic requirements for ubuntu
```shell
 apt-get -y update && apt-get -y upgrade
 apt-get -y install git curl wget
 mkdir -p /opt/config/production/git && \
       cd /opt/config/production/git && \
 GIT_SSL_NO_VERIFY=true git clone https://review.forj.io/forj-oss/maestro
```
- Install puppet
```shell
 /opt/config/production/git/maestro/puppet/install_puppet.sh 
```
- Install 3rd party modules
```shell
 /opt/config/production/git/maestro/puppet/install_modules.sh 
```
- Install hiera
```shell
 /opt/config/production/git/maestro/hiera/hiera.sh 
```

- Install required gems 
```shell
    gem1.8 install bundler --no-rdoc --no-ri
    bundle install --gemfile .gemfile
```

### Run Test ###
- Setup fog file configuration as described below
```shell
  rake spec
```

### Perform lint testing ###
```shell
  rake lint
```

### Test setup automation ###
  Use these modules to setup an automated build server for testing:

```shell
  puppet -e "include gardener
  include compiler_tools::install::rubydev
  include compiler_tools::install::puppetlint"
```

  Now your ready for testing.   You can do this by running the commands in the 
  same directory as the Rakefile.

```shell
  rake lint
  rake spec
```

## Fog file configuration ##
  - The cloud.fog file by default is located in /opt/config/fog/cloud.fog.
  - This file should be secured by root, read / writable by root.  It will
    contain credentials for managing compute/network/dns resources in your 
    cloud accounts for the tenants specified.  This means the instance will
    be able to create and destroy resources as needed.
  - The configuration file follows specification as required by fog. Documentation
    on this can be found here: http://fog.io/about/getting_started.html  
    Read on the credentials section.
  - In addition to each section we require a section for default provider we
    will use for api connectivity.  This will help us distinguish between
    using openstack api's or other provider apis.  This section is called :
```yaml
        forj:
          provider: <name>   where name is hp|ec2|rackspace|openstack
```
  - Here is an example configuration file we use for testing.  Note that the
    access key and secret key are omitted here for security reasons.

```yaml
  default:
    hp_access_key: <your access key>
    hp_secret_key: <your security key>
    hp_auth_uri: https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/
    hp_tenant_id: 10296473968402
    hp_avl_zone: az-3.region-a.geo-1
    hp_account_id:
  dns:
    hp_access_key: <your access key>
    hp_secret_key: <your security key>
    hp_auth_uri: https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/
    hp_tenant_id: 10820682209898
    hp_avl_zone: region-a.geo-1
    hp_account_id:
  forj:
    provider: hp
```

   In this example, we use hp cloud for providing both compute and dns management.
   The tenant / project we use are two separate projects and availability zones.

   After running gardener, you will also have access to hpcloud cli, that you 
   can use to run other commands to do things such as verify account access or
   manage other resources manually.
   Notice that gardener will always use "dns:" for dns operations, and "default:"
   for compute / network operations.   You can specify different fog configuration
   files by setting the FOG_RC environment variable to different files when
   executing gardener commands.

## Debugging tips ##

- Use export FOG_DEBUG=true , this will show excon debug output ... note, passwords will show up to.
- Use export SPEC_PP_OFF=false, this will turn off the :apply flag and prevent puppet apply steps.
- Use ruby-debug + debugger statement in source, this enables interactive debugging on source.
    rake debugging can be done with rdebug rake spec.
    rspec debugging can be done with rspec -d <spec file>
    rspec debugging when called from rake can be done by setting SPEC_OPTS='-d' export

## LICENSE ##

 (c) Copyright 2014 Hewlett-Packard Development Company, L.P.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

