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

describe 'meta_location', :default=> true do
  # setup hiera
  hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
  # grab hiera seed data, to change it , update test.yaml
  meta_location = hiera.lookup('meta_location', nil, nil)
  ipaddress = hiera.lookup('test_ipaddress', nil, nil)
  forjsite_id = hiera.lookup('forjsite_id', nil, nil)
  forjdomain  = hiera.lookup('forjdomain',nil, nil)
  

  before do
    require 'json'
    meta_data = {
      "erodomain" => forjdomain,
      "eroip" => ipaddress,
      "kitopsip" => ipaddress,
      "cdksite" => forjsite_id,
      "cdkdomain" => forjdomain,
      "erosite" => "maestro.#{forjsite_id}.#{forjdomain}"
    }
    if !File.exist?(meta_location)
      File.open(meta_location,"w") do |f|
        f.write(meta_data.to_json)
      end
    end
    Facter.fact(:erodomain).stubs(:value).returns(meta_data["erodomain"])
    Facter.fact(:eroip).stubs(:value).returns(meta_data["eroip"])
    Facter.fact(:kitopsip).stubs(:value).returns(meta_data["kitopsip"])
    Facter.fact(:cdksite).stubs(:value).returns(meta_data["cdksite"])
    Facter.fact(:cdkdomain).stubs(:value).returns(meta_data["cdkdomain"])
    Facter.fact(:erosite).stubs(:value).returns(meta_data["erosite"])
    Facter.fact(:meta_location).stubs(:value).returns(meta_location)

    Facter.fact(:ipaddress).stubs(:value).returns(ipaddress)  # setting this to any value so we can test lookup
  end

  it "finds facter meta_location value #{meta_location}" do
    puts Facter.fact(:meta_location).value
    meta_loc = Facter.fact(:meta_location).value.should == meta_location
  end

  it "finds facter erodomain value #{forjdomain}" do
    puts Facter.fact(:erodomain).value
    meta_loc = Facter.fact(:erodomain).value.should == forjdomain
  end

  it "finds facter eroip value #{ipaddress}" do
    puts Facter.fact(:eroip).value
    meta_loc = Facter.fact(:eroip).value.should == ipaddress
  end

  it "finds facter kitopsip value #{ipaddress}" do
    puts Facter.fact(:kitopsip).value
    meta_loc = Facter.fact(:kitopsip).value.should == ipaddress
  end

  it "find facter cdksite value #{forjsite_id}" do
    puts Facter.fact(:cdksite).value
    meta_loc = Facter.fact(:cdksite).value.should == forjsite_id
  end

  it "finds facter cdkdomain value #{forjdomain}" do
    puts Facter.fact(:cdkdomain).value
    meta_loc = Facter.fact(:cdkdomain).value.should == forjdomain
  end

  it "finds a facter erosite" do
    puts Facter.fact(:erosite).value
    meta_loc = Facter.fact(:erosite).value.should == "maestro.#{forjsite_id}.#{forjdomain}"
  end
end
