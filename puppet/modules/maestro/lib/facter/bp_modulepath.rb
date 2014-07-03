# Copyright 2012 Hewlett-Packard Development Company, L.P
#
def debug (msg = "")
  if Object.const_defined?('Puppet')
    Facter.debug msg
  else
    if ENV['FACTER_DEBUG'] == 'true'
      $stdout.puts msg
      $stdout.flush
    end
  end
end

def get_environment
  env = nil
  if defined? Puppet and Puppet.application_name == :agent
    env = Puppet[:environment]
  else
    env = Facter::Util::Resolution.exec('puppet agent --configprint environment')
  end
  return env
end

Facter.add(:bp_modulepath) do
  setcode do
    environment = nil
    begin
      environment = get_environment
      if environment == nil or environment == '' or environment == :undefined
        Facter.warn "bp_modulepath got bad environment value, using production, %s: %s" % [self.name, details]
        environment = 'production'
      end
    rescue Exception => details
      Facter.warn "problem getting environment fact, defaulting to production, %s: %s" % [self.name, details]
      environment = 'production'
    end

    blueprints_path = File.join('','opt','config',environment,'blueprints')
    bp_modulepath = ''
    begin
      if File.exists?(blueprints_path)
        Dir.foreach(blueprints_path) do |item|
            next if item == '.' or item == '..'
            module_path = File.join(blueprints_path , item)
            if File.exists?(module_path) && File.directory?(module_path)
               debug('Blueprint installed: '+item)
              bp_modulepath = bp_modulepath + module_path + ':'
            end
         end
      else
        debug("#{blueprints_path} not found , facter empty")
      end
      # add forj-config path to the module path : /opt/config/production/puppet/modules
      forj_config_spec = File.join('','opt', 'config', environment, 'puppet', 'modules')
      if File.directory?(forj_config_spec)
        bp_modulepath = forj_config_spec + ':' + bp_modulepath
      end
    rescue Exception => e
      debug(e.message)
      debug(e.backtrace.inspect)
    end
    bp_modulepath
  end
end
