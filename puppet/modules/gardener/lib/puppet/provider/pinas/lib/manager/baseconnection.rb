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
#
# manage connections using hp cloud , unix_cli api
# we rely on hpcloud gem libraries to manage our connection for fog.
require 'fog'
require 'yaml'

__LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)
require "provider"

module Manager
  class BaseConnection
    include ::Puppet::PinasProvider
    def initialize(acct_name = :basename)
      @def_acct_name = acct_name
      Puppet.debug "def_acct_name => #{@def_acct_name}"
    end

    # load our fog files, the default is hp account
    def load_fog_options
      info = get_cloud_info
      test_chk = (@account_name.to_sym == @def_acct_name.to_sym)
      Puppet.debug "account_name => #{@account_name} #{test_chk}"
      acct_key = (@account_name.to_sym == @def_acct_name.to_sym) ? :default : @account_name
      Puppet.debug("acct_key => #{acct_key}")
      unless info.has_key?(acct_key.to_s)
        raise "#{get_fog_file} does not specify the account section => #{acct_key}, please be sure to configure this section first."
      end
      acct = {}
      info[acct_key.to_s].each_pair do | key, data |
        acct[key] = data
        acct[key.to_sym] = data
      end
      return acct
    end

  end
end
