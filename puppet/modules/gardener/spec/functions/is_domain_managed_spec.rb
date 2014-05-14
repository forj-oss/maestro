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

# This test case requires a valid cloud.fog file defined by export FOG_RC
# default location is /opt/config/fog/cloud.fog
#
#  Example fog file will contain the dns node.
#  Notice that if az is found in the name, Pinas DNS will remove it for 13.5
#  cdkdev.org. can be found in tenant id 10820682209898
#
#default:
#  hp_access_key: <some access key you generate>
#  hp_secret_key: <some key you generate>
#  hp_auth_uri: https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/
#  hp_tenant_id: 10296473968402
#  hp_avl_zone: az-3.region-a.geo-1
#  hp_account_id:
#dns:
#  hp_access_key: <some access key you generate>
#  hp_secret_key: <some key you generate>
#  hp_auth_uri: https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/
#  hp_tenant_id: 10820682209898
#  hp_avl_zone: az-3.region-a.geo-1
#  hp_account_id:
#forj:
#  provider: hp


describe 'is_domain_managed', :dns => true do
  context 'with default values' do
    it "does have cdkdev.org." do
      should run.with_params('cdkdev.org.').and_return(true)
    end
  end
end

describe 'is_domain_managed', :dns => true do
  context 'with not managed domain' do
    it "does not have scoobydo.com." do
      should run.with_params('scoobydo.com.').and_return(false)
    end
  end
end

