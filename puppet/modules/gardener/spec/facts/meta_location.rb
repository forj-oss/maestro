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
    File.delete(meta_location) if File.exist?(meta_location)
    meta_data = {
      "erodomain" => forjdomain,
      "eroip" => ipaddress,
      "kitopsip" => ipaddress,
      "cdksite" => forjsite_id,
      "cdkdomain" => forjdomain,
      "erosite" => "maestro.#{forjsite_id}.#{forjdomain}"
    }
    File.open(meta_location,"w") do |f|
      f.write(meta_data.to_json)
    end
    Facter.fact(:ipaddress).stubs(:value).returns(ipaddress)  # setting this to any value so we can test lookup
  end

  it "finds a facter meta_location" do
    puts Facter.fact(:meta_location).value
    meta_loc = Facter.fact(:meta_location).value.should == meta_location
  end

  it "finds a facter erodomain" do
    puts Facter.fact(:erodomain).value
    meta_loc = Facter.fact(:erodomain).value.should == forjdomain
  end

  it "finds a facter eroip" do
    puts Facter.fact(:eroip).value
    meta_loc = Facter.fact(:eroip).value.should == ipaddress
  end

  it "finds a facter kitopsip" do
    puts Facter.fact(:kitopsip).value
    meta_loc = Facter.fact(:kitopsip).value.should == ipaddress
  end

  it "find a facter cdksite" do
    puts Facter.fact(:cdksite).value
    meta_loc = Facter.fact(:cdksite).value.should == forjsite_id
  end

  it "finds a facter cdkdomain" do
    puts Facter.fact(:cdkdomain).value
    meta_loc = Facter.fact(:cdkdomain).value.should == forjdomain
  end

  it "finds a facter erosite" do
    puts Facter.fact(:erosite).value
    meta_loc = Facter.fact(:erosite).value.should == "maestro.#{forjsite_id}.#{forjdomain}"
  end
end