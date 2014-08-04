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
module SpecUtilities
  module Puppet
    def apply(content = nil, doexitstatus = false, debug = false)
      debug_opts = (debug == true) ? " --debug --verbose"  : " "
      if content != nil
        puts "running => #{content}"
        return command("puppet","apply#{debug_opts} --modulepath=#{get_module_path} -e \"#{content}\" --detailed-exitcodes", doexitstatus)
      end
    end
    def applynoop(content = nil, doexitstatus = false, debug = false)
      if content != nil
        puts "running => #{content}"
        debug_opts = (debug == true) ? " --debug --verbose"  : " "
        return command("puppet","apply#{debug_opts} --modulepath=#{get_module_path} -e \"#{content}\" --noop --detailed-exitcodes", doexitstatus)
      end
    end
    def get_module_path
      module_root = File.expand_path(File.join(__FILE__, '..'))
      this_module_path = File.expand_path(File.join(module_root,'..','..','..','modules'))
      spec_module_path = File.expand_path(File.join(module_root,'fixtures','modules'))

      if ENV['PUPPET_MODULES'] != nil
        modules = "#{ENV['PUPPET_MODULES']}:#{this_module_path.to_s}:#{spec_module_path}"
        return modules
      else
        puppet_modules_path = ["/etc/puppet/modules", this_module_path,spec_module_path]
        return puppet_modules_path.join(':').to_s
      end
    end
  end
  module Exec
    def command(command, args, doexitstatus = false)
        exit_status = 99
        begin
           command += " "
           command.concat(args)
           puts command
           output = `#{command}`
           exit_status = $?.exitstatus

           output.split(/\r?\n/).each { |line| 
             p line
           }
           puts "Exit Status ( #{exit_status} )"
           return (doexitstatus == false) ? (exit_status == 0) : exit_status
        rescue Exception => e
           puts "Problem running command -> #{command}"
           puts e.message
           return (doexitstatus == false) ? false : exit_status
        end
    end
  end
end
