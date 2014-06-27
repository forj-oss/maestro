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

Puppet.features.add(:array_ext) do
  begin
    ::Array.class_eval do  # changed from class to meta programing style for rspec testing to work.
      def to_hash(spliter = '=')
        hsh = {}
        begin
          if spliter == nil or spliter == ''
            self.each { |o| hsh[o] = spliter}
          else
            self.each { |o| hsh[o.split(spliter)[0]] = o.split(spliter)[1] if o.include? spliter }
          end
        rescue Exception => e
           Puppet.err "problem converting Array to_hash"
           Puppet.err "#{e}"
           return {}
        end
        return hsh
      end
    end

# set true so we know the feature is available.
    true
  rescue Exception => err
    Puppet.warning "Could not load Array_ext: #{err}"
  end
end
