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

#RSpec.configure do |c|
#  c.include PuppetlabsSpec::Files
# 
#  c.before :each do
#    # Ensure that we don't accidentally cache facts and environment
#    # between test cases.
#    Facter::Util::Loader.any_instance.stubs(:load_all)
#    Facter.clear
#    Facter.clear_messages
# 
#    # Store any environment variables away to be restored later
#    @old_env = {}
#    ENV.each_key {|k| @old_env[k] = ENV[k]}
#  end
# 
#  c.after :each do
#    PuppetlabsSpec::Files.cleanup
#  end
#end

describe 'puppetmaster', :default=> true do
    # setup hiera
    hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
    ipaddress = hiera.lookup('test_ipaddress', nil, nil)
    dns_name = hiera.lookup('test_dns_name', nil, nil)
    puppetmaster = String.new
    context 'with master puppet.conf' do
      let(:facts) { {:ipaddress => ipaddress} }
      before do
        Facter.fact(:ipaddress).stubs(:value).returns(ipaddress)
        ENV['FACTER_DEBUG'] = 'true'
        ENV['COMPUTE_VHOST_NAME'] = nil
        ENV['FACTER_CACHE_TTL'] = '0'
        ENV['PUPPET_CONF'] = 'spec/fixtures/puppet.master.conf'
      end
  
      it "find puppetmaster using master file" do
        puppetmaster = Facter.fact(:puppetmaster).value
        puppetmaster.should == dns_name
      end

      after do
        ENV['FACTER_CACHE_TTL'] = nil
        ENV['PUPPET_CONF'] = nil
#        Facter.clear
#        Facter.clear_messages
      end
    end

#TODO: FIX , puppetmaster facter is being cached, how can we clear the cache without getting 
#            into an endless loop.
#    context 'with agent puppet.conf' do
#      let(:facts) { {:ipaddress => ipaddress} }
#      before do
##        Facter.clear
## Didn't work        Facter.fact(:puppetmaster).stubs(:value).returns(nil) = nil if Facter.fact(:puppetmaster) != nil
#        Facter.fact(:ipaddress).stubs(:value).returns(ipaddress)
#        ENV['FACTER_DEBUG'] = 'true'
#        ENV['COMPUTE_VHOST_NAME'] = nil
#        ENV['FACTER_CACHE_TTL'] = '0'
#        ENV['PUPPET_CONF'] = 'spec/fixtures/puppet.agent.conf'
#      end
#  
#      it "find puppetmaster using agent file" do
##debugger
#        puppetmaster = Facter.fact(:puppetmaster).value
#        puts "puppetmaster => #{puppetmaster}" 
#        puts "puppetmaster => #{puppetmaster.class}" 
#        puppetmaster.should == nil
#      end
##
#      after do
#        ENV['FACTER_CACHE_TTL'] = nil
#        ENV['PUPPET_CONF'] = nil
###        Facter.clear
###        Facter.clear_messages
#      end
#    end

end
