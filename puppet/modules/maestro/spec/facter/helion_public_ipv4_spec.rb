# == maestro::helion_public_ipv4
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

require 'spec_helper'

describe 'helion_public_ipv4', :default=> true do
    # setup hiera
    public_ip = nil
    before do
      public_ip = Facter.fact(:helion_public_ipv4).value.to_s
    end

    it "finds public ip address" do
      public_ip.should_not be_nil
    end

    after do
       puts "Found ip #{public_ip}"
    end

end
