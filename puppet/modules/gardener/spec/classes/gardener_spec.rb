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

describe 'gardener', :default => true do
#  let(:params) { {:foo => 'bar', :baz => 'gronk'} }
#  let(:title) { 'nginx' }
  context 'with default values' do
    it { should contain_class('gardener::requirements') }
    it { should compile }
  end

  context 'has packages requirements' do

    it { should contain_package('mime-types').with(
          {
            'ensure'   => '1.25.1',
            'provider' => 'gem18',
          }
        )}
    it { should contain_package('excon').with(
         {
           'ensure'   => '0.31.0',
           'provider' => 'gem18',
         }
       )}
    it { should contain_package('nokogiri').with(
         {
           'ensure'   => '1.5.11',
           'provider' => 'gem18',
         }
       )}
    it { should contain_package('fog').with(
         {
           'ensure'   => '1.19.0',
           'provider' => 'gem18',
         }
       )}
    it { should contain_package('dos2unix').with(
         {
           'ensure'   => 'latest',
         }
       )}
    it { should contain_package('libxslt-dev').with(
        {
          'ensure'   => 'latest',
        }
      )}
    it { should contain_package('hpcloud').with(
          {
            'ensure'   => '2.0.8',
          }
        )}
  end
end
