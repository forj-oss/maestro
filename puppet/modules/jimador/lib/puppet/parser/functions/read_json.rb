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
require 'json' if Puppet.features.json?

module Puppet::Parser::Functions
  newfunction(:read_json, :type => :rvalue) do |args|
     unless  Puppet.features.json?
      # TODO(wenlock): we should find out if there is a better way to do logging or output with puppet
       Puppet.debug "unable to continue with save due to json not loaded."
     return ''
    end

    @tool_name = args[0] #"gerrit"
    @property = args[1] # "tool_url"
    @jsonfile_location = args[2] #"/home/ubuntu/ero-ui/config/config.json"
    @only_ip = args[3] #true

    if File.exists?(@jsonfile_location)
      json = File.read(@jsonfile_location)
      sitejson = JSON.parse(json)
      for index_node in (0...sitejson["site"]["node"].length)
        for index_tool in (0...sitejson["site"]["node"][index_node]["tools"].length)
          if sitejson["site"]["node"][index_node]["tools"][index_tool]["name"] == @tool_name
            if @only_ip == true
              a = (sitejson["site"]["node"][index_node]["tools"][index_tool][@property] != nil ? sitejson["site"]["node"][index_node]["tools"][index_tool][@property].gsub(/^(https?|ftp):\/\//, '') : '')
              a = a.gsub(/\/$/,'')
              a = a.gsub(/:\d+/,'')
            else
              a = (sitejson["site"]["node"][index_node]["tools"][index_tool][@property] != nil ? sitejson["site"]["node"][index_node]["tools"][index_tool][@property] : '')
            end
          end
        end
      end
      (a != nil ? a : '')
    end
  end
end
