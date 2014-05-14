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

# Puppet apply test case.
# Test the parser function for getting public ip address for a given resource
# requires that the resource be created,ie; server_up_test
# This requires fog configuration, if possible schedule test case in 
# rakefile to sequence after server_up_test



describe "apply test compute_public_ip_lookup", :if => true, :apply => true do
  context 'with puppet apply' do
    it "should find a node called serverupnode1.42" do
      apply("notice(compute_public_ip_lookup('serverupnode1.42'))").should be(true)
    end
  end
end

describe "apply test compute_public_ip_lookup with fake node", :if => false, :apply => true do
  context 'with puppet apply' do
    it "should not find a node called foo" do
      apply("notice(compute_public_ip_lookup('foo'))").should be(false)
    end
  end
end