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
require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'spec_utilities'
include ::SpecUtilities::Puppet
include ::SpecUtilities::Exec
def is_dns_enabled?
  begin
    fog = YAML.load_file(ENV['FOG_RC'])["dns"]
    return (fog != nil)
  rescue Errno::ENOENT
    return false
  end
end

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

# build paths

RSpec.configure do |c|
  c.module_path = get_module_path
  puts "[configure/puppet_apply] using modulepath : #{c.module_path}"
  c.manifest_dir = File.join(fixture_path, 'manifests')
  puts "[configure/puppet_apply] using manifest_dir : #{c.manifest_dir}"
  c.config       = "/etc/puppet/puppet.conf"
  c.hiera_config = "/etc/puppet/hiera.yaml"
end

RSpec.configure do |c|
#  c.color_enabled = true    option not available...TODO
  c.tty = true
  c.formatter = :documentation # :progress, :html, :textmate
  spec_pp_off = ENV['SPEC_PP_OFF']
  puts "[configure/puppet_apply] export SPEC_PP_OFF to prevent puppet apply test, currently SPEC_PP_OFF => #{spec_pp_off}"
  is_run_puppet_apply = ((spec_pp_off == '' || spec_pp_off == nil) ? true : false)
  puts "[configure/puppet_apply] Running with puppet apply set to #{is_run_puppet_apply}"
  c.filter_run :apply => is_run_puppet_apply
  c.filter_run :default => true
  c.filter_run :dns => is_dns_enabled?
end

