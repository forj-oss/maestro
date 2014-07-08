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


describe 'compute_vhost_name', :default=> true do
    # setup hiera
    hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
    ipaddress = hiera.lookup('test_ipaddress', nil, nil)
    dns_name = hiera.lookup('test_dns_name', nil, nil)
    context 'with private ipaddress facter' do
      let(:facts) { {:ipaddress => ipaddress} }
      before do
        Facter.fact(:ipaddress).stubs(:value).returns(ipaddress)
        ENV['FACTER_DEBUG'] = 'true'
        ENV['COMPUTE_VHOST_NAME'] = nil
        ENV['FACTER_CACHE_TTL'] = '0'
      end
  
      it "finds the vhost_name based on #{ipaddress} value" do
        Facter.fact(:compute_vhost_name).value.should == dns_name
      end

      after do
        ENV['FACTER_CACHE_TTL'] = nil
#        Facter.clear
#        Facter.clear_messages
      end
    end

#    context 'with ENV COMPUTE_VHOST_NAME set' do
#      let(:facts) { {:ipaddress => ipaddress} }
#      before do
#        ENV['FACTER_DEBUG'] = 'true'
#        ENV['COMPUTE_VHOST_NAME'] = 'spectester.foo.com'
#        ENV['FACTER_CACHE_TTL'] = nil
#      end
#  
#      it "finds the vhost_name based on environment value" do
#        Facter.fact(:compute_vhost_name).value.should == 'spectester.foo.com'
#      end
#
#      after do
#        ENV['COMPUTE_VHOST_NAME'] = nil
#        ENV['FACTER_CACHE_TTL'] = nil
#        Facter.clear
#      end
#    end
#
#    context 'with meta_compute_vhost_name set' do
#      let(:facts) { {:meta_compute_vhost_name => 'spectester2.bar.com',
#                     :ipaddress => ipaddress} }
#
#      before do
#        ENV['FACTER_DEBUG'] = 'true'
#        ENV['COMPUTE_VHOST_NAME'] = nil
#        ENV['FACTER_CACHE_TTL'] = nil
#      end
#  
#      it "finds the vhost_name based on meta value" do
#        Facter.fact(:compute_vhost_name).value.should == 'spectester2.bar.com'
#      end
#
#      after do
#        ENV['FACTER_CACHE_TTL'] = nil
#        Facter.clear
#      end
#    end
end
