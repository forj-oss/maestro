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

# convert an array to a hash on = or split argument

module Puppet::Parser::Functions
  newfunction(:joinpath, :type => :rvalue, :doc => <<-EOS
Functions joins two strings together with proper slash from platform 
currently running on.

*Arguments:*
  path     : path for a folder, does not have to exist.
  path2/name: second argument appends

*Examples:*
 
  joinpath( string1, string2,...) 

returns : string1/string2 on Linux and string1\\string2 on windows

    EOS
   ) do |arguments|
       Puppet.debug "joinpath.."
       unless (arguments.size >= 2) then
          raise(Puppet::ParseError, "joinpath(): Wrong number of arguments "+
            "given #{arguments.size} we need at least 2 arguments")
       end
       path_spec = ''
       begin
         arguments.each do | data | 
           path_spec = File.join(path_spec, data)
         end
       rescue Exception => e
         Puppet.err "problem in joinpath"
         Puppet.err "#{e}"
         raise "problem joining path, error => #{e}"
       end
       Puppet.debug "returning #{path_spec}"
       path_spec
    end
end
