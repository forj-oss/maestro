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

# create test data with :
custom_dir = './spec/fixtures/cacerts/custom/'
custom_dir = File.expand_path custom_dir

describe 'cacerts::unprotect', :default => true do
  # setup hiera
  let(:params) { {:pass => 'test'} }
  let(:title) { custom_dir }
  context 'with defaults' do
    it { should compile }
  end
end

describe "puppet apply unprotect", :apply => true do
  context 'with valid locked_key' do
    before do
      File.delete(File.join(custom_dir, 'review.yourdomain.com.locked_key')) if File.exist?(File.join(custom_dir, 'review.yourdomain.com.locked_key'))
      File.delete(File.join(custom_dir, 'review.yourdomain.com.key')) if File.exist?(File.join(custom_dir, 'review.yourdomain.com.key'))
      FileUtils.mkdir_p custom_dir
      `openssl genrsa -passout pass:test -des3 -out #{custom_dir}/review.yourdomain.com.locked_key 2048`
    end
    it "should create unprotected key files." do
        
        define_class = "
                cacerts::unprotect{'#{custom_dir}':
                        pass            => 'test',
                }
            "
        apply(define_class, true).should be <= 2
    end
    it "creates review.yourdomain.com.key" do 
       File.exist?(File.join(custom_dir, "review.yourdomain.com.key")).should be_true
    end
  end
end
