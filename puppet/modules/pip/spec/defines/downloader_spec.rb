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

describe 'downloader', :default => true do
  # setup hiera
  hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
  url   = hiera.lookup('download_url', nil, nil)
  md5   = hiera.lookup('download_md5', nil, nil)
  let(:params) { {:ensure => 'present',
                  :path => 'spec/fixtures',
                  :md5 => md5,
                  :replace => true,
                  :provider => 'url'} }
  let(:title) { url }
  context 'with defaults' do
    it { should compile }
  end
end

describe "downloader default url", :apply => true do
  context 'with hiera :download_url' do
    hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
    url   = hiera.lookup('download_url', nil, nil)
    md5   = hiera.lookup('download_md5', nil, nil)
    name  = hiera.lookup('download_name', nil, nil)
    download_def = "
      downloader {'#{url}':
        ensure   => present,
        path     => './spec/fixtures/#{name}',
        md5      => '#{md5}',
        owner    => 'root',
        group    => 'root',
        mode     => 755,
        replace  => true,
        provider => url,
      }
    "
    it "downloads default url." do
        apply(download_def, true).should be <= 2
    end
  end
  context "with hiera :download2_url" do
    hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
    url   = hiera.lookup('download2_url', nil, nil)
    md5   = hiera.lookup('download2_md5', nil, nil)
    name  = hiera.lookup('download2_name', nil, nil)
    download2_def = "
      downloader {'#{url}':
        ensure   => present,
        path     => './spec/fixtures/#{name}',
        md5      => '#{md5}',
        owner    => 'root',
        group    => 'root',
        mode     => 755,
        replace  => true,
        provider => url,
      }
    "
    it "downloads second url." do
       apply(download2_def, true).should be <= 2
    end
  end
end
