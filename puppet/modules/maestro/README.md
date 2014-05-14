forj/maestro
=====================

Rendering engine for forj blueprints. 
 
 
## Usage ##
   Implements orhestration integration, forj administrative gui, landing page
   and forj api interfaces.
   
## Install ##

   include maestro
   
   

## Features ##

  - orchestrate static blueprint node creation on hpcloud, openstack
  - manage dns zones
  - kitops read/write api for key value pair management
  - kitops to facter articulation
  - maestro id management
  - maestro ui for admin registration and tools rendering
  - blueprint api for read/only configuration management
  - backup management
  - ssl, https, ssh key and domain key management
  

## WIP ##
  - ui will have project and user management
  - full ha proxy management

## Planned ##

## Intended Audience ##
  users of forj kits
  
## Testing ##
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

