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
module SpecUtilities
  module Puppet
    def apply(content = nil, debug = false)
      debug_opts = (debug == true) ? " --debug --verbose"  : " "
      if content != nil
        puts "running => #{content}"
        return command("puppet","apply#{debug_opts} --modulepath=#{get_module_path} -e \"#{content}\"")
      end
    end
    def apply_matchoutput(content = nil, match_output = nil, debug = false)
      debug_opts = (debug == true) ? " --debug --verbose"  : " "
      if content != nil
        puts "running => #{content}"
        output =  command_out("puppet","apply#{debug_opts} --modulepath=#{get_module_path} -e \"#{content}\"")
        output.split(/\r?\n/).each { |line| 
           return true if match_output != nil and (match_output.is_a?(Regexp) and match_output =~ line)
           return true if match_output != nil and (match_output.is_a?(String) and match_output == line)
         }
      end
      return false
    end
    def applynoop(content = nil, debug = false)
      if content != nil
        puts "running => #{content}"
        debug_opts = (debug == true) ? " --debug --verbose"  : " "
        return command("puppet","apply#{debug_opts} --modulepath=#{get_module_path} -e \"#{content}\" --noop")
      end
    end
    def get_module_path
      if ENV['PUPPET_MODULES'] != nil
        return ENV['PUPPET_MODULES']
      else
        module_root = File.expand_path(File.join(__FILE__, '..'))
        this_module_path = File.expand_path(File.join(module_root,'..','..','..','modules'))
        puppet_modules_path = ["/etc/puppet/modules", this_module_path]
        return puppet_modules_path.join(':').to_s
      end
    end
  end
  module Exec
    def command(command, args)
        begin
           command += " "
           command.concat(args)
           output = `#{command}`
           exit_status = $?.exitstatus
           
           output.split(/\r?\n/).each { |line| 
             p line
           }
           return (exit_status == 0)
        rescue
           return false
        end
    end
    def command_out(command, args)
        begin
           command += " "
           command.concat(args)
           output = `#{command}`
           exit_status = $?.exitstatus
           output.split(/\r?\n/).each { |line| 
               p line
             }
           
           return output
        rescue
           return nil
        end
    end
  end
end