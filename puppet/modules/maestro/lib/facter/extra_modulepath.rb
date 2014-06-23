# Copyright 2012 Hewlett-Packard Development Company, L.P
#

# note: this really checks for apache2, which proxies the puppet dashbooard, if apache2
#       is down then the dashboard is not available (eventhough puppet system is ok)
def debug (msg = "")
  if Object.const_defined?('Puppet')
    Puppet.debug 'facter(extra_modulepath):'+msg
  else
    if ENV['FACTER_DEBUG'] == 'true'
      $stdout.puts msg
      $stdout.flush
    end
  end
end


Facter.add(:extra_modulepath) do
  setcode do
    extra_modulepath = ''
    additional_mods_path = '/opt/config/production/puppet/modules'
    begin
       modName=Dir.glob(additional_mods_path+'/*')
       modName.each do |item|
          debug('checking if we found at least one module ie "' + item + '/*/manifests"')
          foundModules=modName=Dir.glob(item+'/*/manifests')
          if foundModules.count >0
             debug('Additional modules installed: '+item)
             extra_modulepath = extra_modulepath + item + ':'
          end
       end
    rescue Exception => e
      debug(e.message)
      debug(e.backtrace.inspect)
    end 
    extra_modulepath
  end
end
