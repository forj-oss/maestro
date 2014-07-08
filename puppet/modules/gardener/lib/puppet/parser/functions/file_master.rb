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
  newfunction(:file_master, :type => :rvalue, :doc => <<-EOS
Reads a file and returns it's content only if this is not 
the puppet master.
Relies on facter puppetmaster = <hostnmae>

*Arguments:*
  path     : path to a file

*Examples:*
 
  file_master( path ) 

returns : contents of file at path

    EOS
   ) do |arguments|
       Puppet.debug "file_master.."
       unless (arguments.size == 1) then
          raise(Puppet::ParseError, "file_master(): Wrong number of arguments "+
            "given #{arguments.size} we need 1 argument")
       end
       path_spec = arguments[0]
       content = nil
       begin
         master_name = lookupvar('puppetmaster')
         content = File.read(path_spec) if master_name != nil and master_name != '' and File.exist? path_spec
       rescue Exception => e
         Puppet.err "problem in file_master"
         Puppet.err "#{e}"
         raise "problem file_master => #{path_spec}, error => #{e}"
       end
       Puppet.debug "file_master done #{path_spec}"
       content
    end
end
