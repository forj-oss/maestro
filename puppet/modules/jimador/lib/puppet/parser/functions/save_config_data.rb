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
   newfunction(:save_config_data,:doc => <<-EOS
This function is used to manage maestro config.json.  Write a new configuration
section to config.json under specified node.
*Arguments:*
  path     : can be site... TBD for implementing other lvls
  property : name of the property to set
  data     : property data to configure, should be simple types like 
             array , number, string, binary 
*Examples:*
 
  save_config_data( 'site', $property_name, $data)

returns : nothing

    EOS
   ) do |args|
       unless  Puppet.features.json?
        Puppet.debug "unable to continue with save due to json not loaded."
        return
       end
       
       if (args.size != 3) then
          raise(Puppet::ParseError, "save_config_data: Wrong number of arguments "+
            "given #{args.size} for 3")
       end
       
       @type = args[0]
       @key  = args[1]
       @data = args[2]
       @supported_types = ['site']
      unless @supported_types.include?(@type)
         raise(Puppet::ParseError, "specified type is unsuported, must use #{@supported_types}")
      end

      Puppet.debug "working with key => #{@key}"
      Puppet.debug "working with data => #{@data}"
       chelper = Puppet::CrupHelper.new( nil,   # tool 
                                         nil,   # name
                                         [],    # properties
                                         [],    # values
                                         nil,   # default_tools
                                         [],    # filter_tools
                                         self,  # puppet
                                         false) # create_config
       if chelper.is_initialized?
         chelper.add_sitekey(@key) if @type == 'site' and !chelper.sitekey_exist?(@type)
         chelper.set_sitekey(@key, @data)
         chelper.save                 # saves changes to the config
       end

    end
end