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

# convert object to json


require 'json'      if Puppet.features.json?

module Puppet::Parser::Functions
  newfunction(:to_json, :type => :rvalue, :doc => <<-EOS
This function will attempt to take an input object and 
convert it to json.

*Arguments:*
  object     : some object

*Examples:*
 
  to_json( [1,2,3] )

returns : {1,2,3}

    EOS
   ) do |arguments|
       Puppet.debug "in to_json.."
       unless  Puppet.features.json?
         Puppet.warning "to_json requires json gem to be installed."
         return nil
       end
       if (arguments.size != 1) then
          raise(Puppet::ParseError, "to_json(): Wrong number of arguments "+
            "given #{arguments.size} for 1")
       end
       res_json = nil
       begin
         res_json = JSON.generate arguments[0]
       rescue Exception => e
         Puppet.err "problem converting object to_json"
         Puppet.err "#{e}"
         raise "problem converting object to_json"
       end
       return res_json
    end
end
