# == maestro::registration_endpoint
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
# used to identify what the forj registration endpoint url is for a running forj.
#
require 'facter'
include ::Puppet::ForjCommon if Puppet.features.forj_common?
include ::Puppet::Forj if Puppet.features.net_helper?
#
# define facter in a way we can do testing
#
module Puppet
  module ForjFacters
    def self.add_registration_endpoint
      Facter.add("registration_endpoint") do
       setcode do
          debug "running registration_endpoint"
          utilurl = UtilURI.new
          kitops_uri = nil
          kitops_uri = Facter.value('kitops_endpoint')
          git_branch = Facter.value('gitbranch')
          endpoint = ""
          if kitops_uri == nil or kitops_uri == ""
            # we can't obtain the current endpoint because there is no kitops
            # lets make a guess.
            debug "got empty kitops_endpoint registration_endpoint based on #{git_branch}"
            endpoint = ::Puppet::ForjFacters.static_registration_endpoint_lookup(git_branch)
          else
            # TODO: need to implement reading the endpoint from kitops endpoint
            # get the endpoint from kitops service
            debug "kitops endpoint was available but un-implemented."
            endpoint = ::Puppet::ForjFacters.static_registration_endpoint_lookup(git_branch)
          end
          endpoint.to_s
       end
      end
    end
    
    def self.static_registration_endpoint_lookup(branch = nil)
      endpoint = ""
      case branch
        when "stable"
          endpoint = 'http://reg.forj.io:3135/devkit'
        when "test-stable"
          endpoint = 'http://reg-test.forj.io:3134/devkit'
        when "master"
          endpoint = 'http://reg-dev.forj.io:3131/devkit'
        else
          endpoint = 'http://reg-dev.forj.io:3131/devkit'
      end
      debug "returning static endpoint => #{endpoint}"
      return endpoint
    end
  end
end
# Load the facter
::Puppet::ForjFacters.add_registration_endpoint

