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

#TODO: need to do some more research on how to make this work, for now 
# lets use the apply test
#require 'lib/facter/registration_endpoint'
#
#describe 'registration_endpoint fact', :type =>fact do
#
#  let(:fact) { Facter.fact(:registration_endpoint) }
#  subject(:registration_endpoint) { fact.value }
#
#  before :each do
#    # Ensure we're populating Facter's internal collection with our Fact
#    Facter.fact(:kernel).stubs(:value).returns(kernel)
#    ::Puppet::ForjFacters.add_registration_endpoint
#  end
#
#  # A regular ol' RSpec example
#  context 'on Linux' do
#        let(:kernel) { 'Linux' }
#        its(:value) { should eql("") }
#  end
#
#  after :each do
#    # Make sure we're clearing out Facter every time
#    Facter.clear
#    Facter.clear_messages
#  end
#end

require 'spec_helper'


describe 'registration_endpoint', :default=> true do
    # setup hiera
    hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
    branchdev = hiera.lookup('gitbranch_dev', nil, nil)
    regurldev = hiera.lookup('regbranch_dev',nil,nil)

    context 'with gitbranch master' do
      let(:facts) { {:gitbranch => branchdev} }

      before do
        ENV['FACTER_DEBUG'] = 'true'
      end

      it "finds endpoint url with value #{branchdev}" do
        Facter.fact(:registration_endpoint).value.should == regurldev
      end
    end
end
