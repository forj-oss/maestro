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


module Puppet::Parser::Functions
   newfunction(:join_arrpattern, :type => :rvalue,:doc => <<-EOS
This function will take a string pattern in the first argument and 
  join it unlimitted additional arguments as specified by the pattern
  in the first argument.

  %s - represents a string.
  %a - represents an array, currently only 1 instance can be specified.
  
  The result is an array with all possible strings from provided array.


*Examples:*

    join_arrpattern('%s-%a.%s','42',['util','ci'], 'cdkdev.org')
    join_arrpattern('%a.%s',['util','ci'], '42.forj.io')

returns : ['42-util.cdkdev.org', '42-ci.cdkdev.org']

    EOS
   ) do |args|

     if (args.size <= 1) then
        raise(Puppet::ParseError, "join_arrpattern: requires at least two  arguments, #{args.length}.")
     end
     raise(Puppet::ParseError, "join_arrpattern: only supports 1 %a pattern.") if args[0].scan(/(\%a)/).flatten.compact.length > 1
     @pattern = args[0].scan(/((.*)(\%[sa])(.*)(\%[sa])(.*))/).flatten.compact
     @verify  = args[0].scan(/(\%[sa])*(\%[sa])*/).flatten.compact
     Puppet.debug "join_arrpattern verify #{@verify.join(',').to_s} size #{@verify.length}"
     verif_arg_size = args.length - 1
     if @verify.length != verif_arg_size then
       raise(Puppet::ParseError, "join_arrpattern: argument and pattern mismatch, arguments to process are #{verif_arg_size} and it should be #{@verify.length}.")
     end
     
     @verify.each_with_index.each { |type, i |
         if type == "%s"
           raise(Puppet::ParseError, "join_arrpattern: argument #{i + 1} has a type error in pattern, expected String.") if ! args[i + 1].kind_of?(String)
         elsif type == "%a"
           raise(Puppet::ParseError, "join_arrpattern: argument #{i + 1} has a type error in pattern, expected Array.") if ! args[i + 1].kind_of?(Array)
         else
           raise(Puppet::ParseError, "unknown pattern #{type} was found.")
         end
     }
     result = []
     Puppet.debug "join_arrpattern #{@pattern.join(',').to_s} size #{@pattern.length}"
     # first replace all the strings
     arg_index = 1
     @pattern.each_with_index.each { |pval, i|
       if i > 0 then
         if pval.include?("%s")
           @pattern[i] = @pattern[i].sub "%s", args[arg_index]
           arg_index = arg_index + 1
         elsif pval.include?("%a")
           @pattern[i] = @pattern[i].sub "%a", "%{x#{arg_index}}"
           arg_index = arg_index + 1
         end
       end
     }
     Puppet.debug "join_arrpattern #{@pattern.join(',').to_s} size #{@pattern.length}"
     # now work on the Arrays in the arguments and add to each result
     @template = @pattern.slice(1,@pattern.length).join
     Puppet.debug "join_arrpattern, @arrpat = #{@template}."
     @arg_arrvals  = @template.scan(/(\%\{x(.)\})/).flatten.compact
     if @arg_arrvals.length == 2 then
        Puppet.debug "join_arrpattern arg_arrvals #{@arg_arrvals.join(',').to_s} size #{@arg_arrvals.length}"
        i = @arg_arrvals[1].to_i # argument index value
        args[i].each_with_index.each { |aval, y|
          result << @template.sub("%{x#{i}}", aval)
        }
     end
     Puppet.debug "join_arrpattern, result = #{result.join(',')}."
     return result
    end
end