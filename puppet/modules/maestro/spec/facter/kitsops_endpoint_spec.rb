# == maestro::kitops_endpoint
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



# this really isn't doing much other than making sure our code compiles
require 'spec_helper'
describe "apply show kitops_endpoint", :apply => true do
  context 'with puppet apply' do
    it "has notice message for kitops_endpoint." do
      apply_matchoutput("notice($::kitops_endpoint)", /warning: Could not load fact file.*/).should be(false)
    end
  end
end