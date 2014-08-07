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

# Test the specification for compute_public_ip_lookup

describe 'cacerts_getkey', :default => true do
  context 'with default values' do
    it "will read file" do
      should run.with_params('./spec/fixtures/test_file.txt').and_return("found")
    end
  end
  context 'with no file to find' do
    it "will read file" do
      should run.with_params('./spec/fixtures/noexist').and_return("")
    end
  end
end
