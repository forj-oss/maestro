# ***************************************************************
# ** store a key
# ***************************************************************

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
 require 'fileutils'
 module Puppet::Parser::Functions
  newfunction(:cacerts_storekey, :type => :rvalue) do |args|
    fspec    = args[0]
    data     = args[1]
    folder   = File.dirname(fspec)
    FileUtils.mkdir_p folder unless File.directory?(folder)
    
    File.open(fspec,"w") do |f|
      f.write(data)
    end
  end
end