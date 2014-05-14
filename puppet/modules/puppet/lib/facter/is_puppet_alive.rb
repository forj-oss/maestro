# Copyright 2012 Hewlett-Packard Development Company, L.P
#

# note: this really checks for apache2, which proxies the puppet dashbooard, if apache2
#       is down then the dashboard is not available (eventhough puppet system is ok)
Facter.add('is_puppet_alive') do
  confine :kernel => 'Linux'
  setcode do
    ret = Facter::Util::Resolution.exec(Facter.value('forj_script_path') + 'toolstatus.sh puppet')
    ret == '0' ? Facter::Util::Resolution.exec('echo true') : Facter::Util::Resolution.exec('echo false')
  end
end