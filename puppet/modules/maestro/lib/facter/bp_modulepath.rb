# Copyright 2012 Hewlett-Packard Development Company, L.P
#
def debug (msg = "")
  if Object.const_defined?('Puppet')
    Puppet.debug msg
  else
    if ENV['FACTER_DEBUG'] == 'true'
      $stdout.puts msg
      $stdout.flush
    end
  end
end

Facter.add(:bp_modulepath) do
  setcode do
    blueprints_path = '/opt/config/production/blueprints'
    bp_modulepath = ''
    begin
      if File.exists?(blueprints_path)
        Dir.foreach(blueprints_path) do |item|
            next if item == '.' or item == '..'
            module_path = blueprints_path + '/' + item
            if File.exists?(module_path) && File.directory?(module_path)
               debug('Blueprint installed: '+item)
              bp_modulepath = bp_modulepath + module_path + ':'
            end
         end
      else
        debug("#{blueprints_path} not found , facter empty")
      end
    rescue Exception => e
      debug(e.message)
      debug(e.backtrace.inspect)
    end
    bp_modulepath
  end
end
