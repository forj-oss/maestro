# == maestro::maestro_id
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
# find various patterns for an id on the server.
# we find patterns in order of precedence 
# *-name -> name.* -> name*
#TODO: need to find how we can have this in a stdlib so we can just do require
def debug (msg = "")
  if Object.const_defined?('Puppet')
    Puppet.debug msg
  else
    if ENV['FACTER_DEBUG'] == 'true'
      $stdout.puts msg
      $stdout.flush
    end
  end
end

Facter.add("maestro_id") do
 setcode do
    #
    debug "maestro_id working on getting id.xxx"
    ero_site   = Facter.value('erosite')
    debug "working with erosite = #{ero_site}"
    maestro_id = ''
    # parse for  ??-name
    pat = ero_site.scan(/(^([a-z0-9]{1,})-(.*))/).flatten.compact
    if pat.length == 3  and pat[1] != '' and pat[1] != nil
      maestro_id = pat[1] if pat[1] != '' and pat[1] != nil
    end
    debug "maestro_id #{maestro_id}, pattern ??-name"

    # parse for instance_id based on name.##
    pat = ero_site.scan(/^((.*)\.([a-z0-9]{1,}))/).flatten.compact
    debug pat.join(',')
    if maestro_id == '' and pat.length == 3  and pat[1] != '' and pat[1] != nil
      maestro_id = pat[2] if pat[2] != '' and pat[2] != nil
    end
    debug "maestro_id #{maestro_id}, pattern  name.??"

    # parse for instance_id based on name##
    # This pattern comes from usage of nodepool, and will likely be needed.
    pat = ero_site.scan(/(^([^0-9\.]+)(.*))/).flatten.compact
    if maestro_id == '' and pat.length == 3  and pat[2] != '' and pat[2] != nil
      maestro_id = pat[2] if pat[2] != '' and pat[2] != nil
    end
    debug "maestro_id #{maestro_id}, pattern  name??"
    maestro_id
 end
end


