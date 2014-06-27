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
  newfunction(:to_hash, :type => :rvalue, :doc => <<-EOS
This function converts an array into a hash.  If no arguments are passed.
The function automatically tries to use = for the element split of the array.
If nil or empty string is passed, the elements will take on the passed value
and only the elements will be used as keys of the hash.

*Arguments:*
  (optional) character     : single character to split the array elements on this value.

*Examples:*
 
  to_hash( [1,2,3] , undef) 

returns : {1,2,3}

    EOS
   ) do |arguments|
       Puppet.debug "in to_hash.."
       unless  Puppet.features.array_ext?
         Puppet.warning "to_hash requires feature array_ext."
         return nil
       end
       unless (arguments.size >= 1) then
          raise(Puppet::ParseError, "to_hash(): Wrong number of arguments "+
            "given #{arguments.size} and we need at least 1 argument")
       end
       res_hash = nil
       begin
         obj = arguments[0]
         Puppet.debug("to_hash -> #{obj.class}")
         Puppet.debug("to_hash #{arguments.size}")
         return (arguments.size >= 2) ? obj.to_hash(arguments[1]) : obj.to_hash if obj.kind_of?(Array)
       rescue Exception => e
         Puppet.err "problem converting object to_hash"
         Puppet.err "#{e}"
         raise "problem converting object to_hash, error => #{e}"
       end
       Puppet.debug "returning empty hash, nothing to do."
       return {}
    end
end
