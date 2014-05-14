# ***************************************************************
# ** read_module_alternate_config
# ***************************************************************
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#TODO: need to decide if we depricate this and remove it.
#      we currently don't have a use case for keeping it.
 module Puppet::Parser::Functions
  newfunction(:read_module_alternate_config, :type => :rvalue, :doc => <<-EOT
    Returns the data from primary config file if it exist, otherwise looks
    for an alternate configuraiton file in a given module.  
    If the file doesn't exist, throws an exception.
    Arguments:
      args[0] - primary path to the config file to look for
      args[1] - name of the module to look for
      args[2] - path to the file in the module, should be relative.
    Example:
      $data = read_module_alternate_config('/opt/config/config.json',
                                    'modulename',
                                    'files/ui/config.json')
  EOT
  )  do |args|
    raise(Puppet::ParseError, "read_module_alternate_config(): Wrong number of arguments, expects three") unless args.size == 3
    filename   = args[0]
    modulename = args[1]
    modulefile = args[2]
    data = nil
    if File.exist? filename
      data = File.read(filename)
    else
      module_path = nil
      if module_path = Puppet::Module.find(modulename, compiler.environment.to_s)
        alt_file = File.join(module_path.path, modulefile)
        raise(Puppet::ParseError, "unable to find alternate module file : #{alt_file}") unless File.exist? alt_file
        data = File.read(alt_file)
      else
        raise(Puppet::ParseError, "Could not find module #{modulename} in environment #{compiler.environment}")
      end 
    end
    return data
  end
end