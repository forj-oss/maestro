# Copyright 2012 Hewlett-Packard Development Company, L.P
#

# note: this really checks for apache2, which proxies the puppet dashbooard, if apache2
#       is down then the dashboard is not available (eventhough puppet system is ok)
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


Facter.add(:extra_modulepath) do
  setcode do
    extra_modulepath = ''
    additional_mods_path = '/opt/config/production/puppet/modules'
    Dir.foreach(additional_mods_path) do |item|
       next if item == '.' or item == '..'
       module_path = additional_mods_path + '/' + item
       debug('checking module "' + item + '" validity : ' + module_path + '/manifests')
       if File.exists?(module_path + '/manifests') && File.directory?(module_path + '/manifests')
          debug('Blueprint installed: '+item)
         extra_modulepath = extra_modulepath + module_path + ':'
       end
    end
    extra_modulepath
  end
end
