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
# common implementation class for server management under pinas
module Puppet
  module PinasComputeHP
    # HP Provider specific methods
    # build a compute fog object
    def get_compute()
     if get_provider != nil
        compute_creds = {
              :provider => get_provider,
              :connection_options => get_connection_options
            }
        version = get_connection_version
        compute_creds[:version] = version if version != nil
        conn = Fog::Compute.new( compute_creds )
        return conn
     else
        raise "Puppet::PinasComputeHP::get_compute unable to get a valid provider from fog configuration file."
        return nil
     end
    end
  end
end
