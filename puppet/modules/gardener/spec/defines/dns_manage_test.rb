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

describe "apply tests dns zone manage present", :apply => true do
  context 'with puppet apply' do
    it "should create dns zone spec.cdkdev.org." do
      apply("include gardener::tests::dns_zone_manage_present").should be(true)
    end
  end
end

describe "apply tests dns zone manage present second time", :apply => true do
  context 'with puppet apply' do
    it "should skip creating dns zone spec.cdkdev.org." do
      apply("include gardener::tests::dns_zone_manage_present").should be(true)
    end
  end
end

describe "apply tests dns record manage present", :apply => true do
  context 'with puppet apply' do
    it "should create dns record pinasdns.spec.cdkdev.org." do
      apply("include gardener::tests::dns_record_manage_present").should be(true)
    end
  end
end

describe "apply tests dns record manage present a second time", :apply => true do
  context 'with puppet apply' do
    it "should skip creating a dns record for pinasdns.spec.cdkdev.org." do
      apply("include gardener::tests::dns_record_manage_present").should be(true)
    end
  end
end

describe "apply tests dns record manage absent", :apply => true do
  context 'with puppet apply' do
    it "should remove the dns record for pinasdns.spec.cdkdev.org." do
      apply("include gardener::tests::dns_record_manage_absent").should be(true)
    end
  end
end

describe "apply tests dns record manage absent a second time", :apply => true do
  context 'with puppet apply' do
    it "should skip the dns record remove for pinasdns.spec.cdkdev.org." do
      apply("include gardener::tests::dns_record_manage_absent").should be(true)
    end
  end
end

describe "apply tests dns zone manage absent", :apply => true do
  context 'with puppet apply' do
    it "should remove the dns zone spec.cdkdev.org." do
      apply("include gardener::tests::dns_zone_manage_absent").should be(true)
    end
  end
end

describe "apply tests dns zone manage absent a second time", :apply => true do
  context 'with puppet apply' do
    it "should skip the dns zone remove for spec.cdkdev.org." do
      apply("include gardener::tests::dns_zone_manage_absent").should be(true)
    end
  end
end