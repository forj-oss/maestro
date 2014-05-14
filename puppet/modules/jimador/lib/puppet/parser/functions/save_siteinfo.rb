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

# load relative libraries
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__)))) unless $LOAD_PATH.include?(File.expand_path(File.join(File.dirname(__FILE__))))


require 'json'      if Puppet.features.json?
require 'lib/cruphelper'

module Puppet::Parser::Functions
   newfunction(:save_siteinfo,:doc => <<-EOS
This function is used to manage maestro config.json file site information.
We will only be managing the site level properties with this function.

*Examples:*

    save_siteinfo('id','en',['util','ci'], '/opt/config/production/config.json')
    save_siteinfo('blueprint','openstack',['util','ci'], '/opt/config/production/config.json')

returns : nothing

    EOS
   ) do |args|
       unless  Puppet.features.json?
        # TODO(wenlock): we should find out if there is a better way to do logging or output with puppet
         Puppet.debug "unable to continue with save due to json not loaded."
        return
       end
       
       if (args.size != 2) then
          raise(Puppet::ParseError, "save_siteinfo: Wrong number of arguments "+
            "given #{args.size} for 2")
       end
       
       @key = args[0]
       @value = args[1]
      

       chelper = Puppet::CrupHelper.new( nil,   # tool
                                         nil,   # name
                                         [],    # properties
                                         [],    # values
                                         nil,   # default_tools
                                         [],    # filter_tools
                                         self,  # puppet
                                         false) # create_config
       if chelper.is_initialized?
          chelper.set_sitekey(@key, @value)
          chelper.save                 # saves changes to the config
       end
        

    end
end