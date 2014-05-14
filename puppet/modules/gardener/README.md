forj/gardener
=====================

Manage cloud things for forj kits.  
 
 
## Usage ##
   For examples on usage see manifests/tests
   
## Install ##

   include gardener
   
   We do this when we can provision our servers, so this gets setup on our .
   puppetmaster

   The gerrit server requires a new empty project called forj-config.

## Features ##

  - class for creating / destroying list of static nodes (server_up, server_destroy)
  - type for managing those nodes: pinas

## WIP ##
  - dns 
  - object storage

## Planned ##
  - attached storage
  - more providers (AWS, rackspace, openstack 13.5)
## Intended Audience ##
  users of forj kits
  
## Testing ##
  setup your environment for testing:
  gem1.8 install bundler
  bundle install --gemfile .gemfile
  
  Requirements, you'll need rake and spec modules.  I also highly recommend puppet-lint.
  You can install bootstrap these with compiler_tools module from forj project.
  This can be done by applying the following puppet manifest:
  
  include compiler_tools::install::rubydev
  include compiler_tools::install::puppetlint
  
  This should now make 'rake lint' and 'rake spec' commands available.
  
  Next step is to install the gardner base requirements.  You can do this with 
  the following puppet manifest : 
       puppet -e "include gardener::requirements"
       
  Now your ready for testing.   You can do this by running the commands in the 
  same directory as the Rakefile.
  
  rake lint
  rake spec

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
        forj:
          provider: <name>   where name is hp|ec2|rackspace|openstack
  - Here is an example configuration file we use for testing.  Note that the
    access key and secret key are omitted here for security reasons.
    
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

   In this example, we use hp cloud for providing both compute and dns management.
   The tenant / project we use are two seperate projects and availability zones.
   
   After running gardener, you will also have access to hpcloud cli, that you 
   can use to run other commands to do things such as verify account access or
   manage other resources manually.
   Notice that gardener will always use "dns:" for dns operations, and "default:"
   for compute / network operations.   You can specify different fog configuration
   files by setting the FOG_RC environment variable to different files when
   executing gardener commands.

## LICENSE ##
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#