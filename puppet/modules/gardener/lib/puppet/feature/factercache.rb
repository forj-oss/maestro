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

Puppet.features.add(:factercache) do
  begin
    # lib
    # TODO: test if we should make a specific check for puppet version
    # this might not apply for puppet 3.x.... seems to apply for 2.7
    __LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
    __LIB_DIR__ = File.join(__LIB_DIR__ , "..")
    __LIB_DIR__ = File.join(__LIB_DIR__ , "..")
    $LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)
    Puppet.features.add(:json, :libs => ["json"])
    Puppet.features.add(:time, :libs => ["time"])
    require "json"
    require "time"
    require "puppet/feature/lib/factercache"
    Puppet.debug "loaded #{__LIB_DIR__}/puppet/feature/lib/factercache"
    true
  rescue Exception => err
    Puppet.warning "Could not load factercache: #{err}"
  end
end