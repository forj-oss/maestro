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
   newfunction(:save_tools,:doc => <<-EOS
This funciton will update the maestro_ui config.json with tools we find.
We want to keep tool status in config.json on the puppet master server.

*Examples:*

  save_tools('node1','gerrit',['status','name','email','tool_url'],['online','gerrit','#','#'],['ci','util'], '/opt/config/production/config.json')

returns : nothing

    EOS
   ) do |args|
       unless  Puppet.features.json?
         Puppet.debug "unable to continue with save due to json not loaded."
        return
       end

       if (args.size > 6) then
          raise(Puppet::ParseError, "save_tools: Wrong number of arguments "+
            "given #{args.size} for a minimum of 5")
       end

        @node            = args[0]
        @tool            = args[1]
        @properties      = args[2]
        @values          = args[3]
        @default_tools   = args[4]
        @filter_tools    = (args.size > 5 ) ? args[5] : []
        @arrayproperties = @properties.split(',')
        @arrayvalues = @values.split('%;')

        chelper = Puppet::CrupHelper.new(@tool,            # tool
                                         @node,            # name
                                         @arrayproperties, # properties
                                         @arrayvalues,     # values
                                         @default_tools,   # default_tools
                                         @filter_tools,    # filter_tools
                                         self,             # puppet
                                         true)             # create_config
        if chelper.is_initialized?
          chelper.remove_default_tool  # clears out any defaults
          chelper.add_node             # adds the node if it's missing
          chelper.add_tool             # adds and updates the tool with the given values
          chelper.save                 # saves changes to the config
        end
    end
end