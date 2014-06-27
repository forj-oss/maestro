require 'rake'
require 'rspec/core/rake_task'

require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

GARDENER_RAKE_ROOT = File.dirname(__FILE__)

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('disable_80chars')

# Disable check due to upstream bug: https://github.com/rodjek/puppet-lint/issues/170
PuppetLint.configuration.send('disable_class_parameter_defaults')

#require 'puppetlabs_spec_helper/rake_tasks'
# This module could be used to instrument the location of a fog_rc file 
# and pull it from a secure location for purposes of this rakefile run
CLOUDCREDS_DIR=(ENV['CLOUDCREDS_DIR'] == nil || ENV['CLOUDCREDS_DIR'] == '') ? '/opt/workspace/git/infra/puppet/modules/cloudcreds' : ENV['CLOUDCREDS_DIR']

Dir.glob("#{CLOUDCREDS_DIR}/Rakefile").each { |r| load r }
def check_cloudcreds

  unless defined?(::CloudCreds::RAKE_ROOT)
    if ENV['FOG_RC'] == nil or ENV['FOG_RC'] == ''
      message = "FOG_RC should be configured or cloudcreds module should be used to define a dynamic FOG_RC \n CLOUDCREDS_DIR => #{CLOUDCREDS_DIR}" 
      raise ArgumentError, message
    else
      return false
    end
  end

  unless File.exist?(::CloudCreds::RAKE_ROOT)
    if ENV['FOG_RC'] == nil or ENV['FOG_RC'] == ''
      message = "FOG_RC should be configured or set CLOUDCREDS_DIR environment, this Rakefile requires cloudcreds module"
      raise ArgumentError, message
    else
      return false
    end
  end
  return true
end

# Check if the FOG_RC export is enabled, and return true
def is_fogrc?
  if ENV['FOG_RC'] != nil and ENV['FOG_RC'] != '' and File.exist?(ENV['FOG_RC'])
    return true
  end
  return false 
end
#
# task definitions
#
Rake::Task["spec"].clear
desc "Default spec execution"
task :spec, :fog_spec do |t, args|
  args.spec(:fog_spec => :default)
  Rake::Task['gardener:spec'].invoke(args[0])
end

namespace :gardener do
  desc "Setup default _spec test"
  RSpec::Core::RakeTask.new(:spec_standalone) do |t|
    t.rspec_opts = ['--color']
    t.pattern = 'spec/{classes,defines,unit,functions,hosts}/**/*_spec.rb'
  end
  RSpec::Core::RakeTask.new(:spec_standalone) do |t|
    t.pattern = 'spec/*/is_domain_managed_test.rb'
  end

  RSpec::Core::RakeTask.new(:spec_standalone) do |t|
    t.pattern = 'spec/*/server_up_test.rb'
  end

  RSpec::Core::RakeTask.new(:spec_standalone) do |t|
    t.pattern = 'spec/*/compute_id_lookup_test.rb'
  end

  RSpec::Core::RakeTask.new(:spec_standalone) do |t|
    t.pattern = 'spec/*/dns_manage_test.rb'
  end

  RSpec::Core::RakeTask.new(:spec_standalone) do |t|
    t.pattern = 'spec/*/server_destroy_test.rb'
  end

  desc "gardener test."
#  task :spec, [:fog_spec] => ['cloudcreds:spec_noclean'] do |t, args|
  task :spec, :fog_spec do |t, args|
    args.spec(:fog_spec => :default)
    puts "Running gardener test... #{args}"
    if ! is_fogrc? and check_cloudcreds
      Rake::Task['cloudcreds:spec_noclean'].invoke(args[0])  #experimental hook for dealing with fog credentials.  Not yet supported.
    end
    cd GARDENER_RAKE_ROOT
    puts "using : #{ENV['FOG_RC']}"
    Rake::Task['gardener:spec_prep'].invoke
    Rake::Task['gardener:spec_standalone'].invoke
    Rake::Task['gardener:spec_clean'].invoke
  end

  desc "Create the fixtures directory"
  task :spec_prep do
    fixtures("repositories").each do |remote, opts|
      if opts.instance_of?(String)
        target = opts
        ref = "refs/remotes/origin/master"
      elsif opts.instance_of?(Hash)
        target = opts["target"]
        ref = opts["ref"]
      end

      unless File::exists?(target) || system("git clone #{remote} #{target}")
        fail "Failed to clone #{remote} into #{target}"
      end
      system("cd #{target}; git reset --hard #{ref}") if ref
    end

    FileUtils::mkdir_p("spec/fixtures/modules")
    fixtures("symlinks").each do |source, target|
      puts "source => #{source}"
      puts "target => #{target}"
      if File::exists?(source)
        File::exists?(target) || FileUtils::ln_s(source, target)
      end
    end

    FileUtils::mkdir_p("spec/fixtures/manifests")
    FileUtils::touch("spec/fixtures/manifests/site.pp")
  end

  desc "Clean up the fixtures directory"
  task :spec_clean do
    fixtures("repositories").each do |remote, opts|
      if opts.instance_of?(String)
        target = opts
      elsif opts.instance_of?(Hash)
        target = opts["target"]
      end
      FileUtils::rm_rf(target)
    end

    fixtures("symlinks").each do |source, target|
      puts "cleaning target => #{target}"
      FileUtils::rm(target)
    end
    site = "spec/fixtures/manifests/site.pp"
    if File::exists?(site) and ! File.size?(site)
      FileUtils::rm("spec/fixtures/manifests/site.pp")
    end
  end
end
