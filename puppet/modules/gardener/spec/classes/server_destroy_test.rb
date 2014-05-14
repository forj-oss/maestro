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
describe 'gardener::server_destroy' do
  let(:params) { {:nodes => ['rspecnode1'], :instance_id => '42'} }
#  let(:title) { 'nginx' }
  context 'with default values' do
    it { should contain_class('gardener::params') }
    it { should contain_class('gardener::requirements') }
    it { should compile }
  end
end
describe "apply test server_destroy", :apply => true do
  it { apply("include gardener::tests::server_destroy").should be(true) }
end
describe "apply test server_destroy second run", :apply => true do
  it { apply("include gardener::tests::server_destroy").should be(true) }
end
