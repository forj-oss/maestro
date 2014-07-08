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


describe 'compute_dns_name', :default=> true do
    # setup hiera
    hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
    ipaddress = hiera.lookup('test_ipaddress', nil, nil)
    dns_name = hiera.lookup('test_dns_name', nil, nil)
    before do
      Facter.fact(:ipaddress).stubs(:value).returns(ipaddress)  # setting this to any value so we can test lookup
      ENV['FACTER_DEBUG'] = 'true'
    end

    it "should find public_ip" do
      puts Facter.fact(:compute_dns_name).value
      Facter.fact(:compute_dns_name).value.should == dns_name
    end

end
