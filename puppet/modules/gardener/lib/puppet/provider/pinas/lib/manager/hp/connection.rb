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
# base lib
__LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
__LIB_DIR__ = File.join(__LIB_DIR__ , "..")
$LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)
require 'baseconnection'

# hpcloud cli libs
require 'hpcloud/config'
require 'hpcloud/accounts'
require 'hpcloud/auth_cache'
require 'hpcloud/version'
require 'hpcloud/connection'

# TODO: require 'fileutils'

module Manager
  module HP
    class Connection < BaseConnection
      # singleton call:
      def self.instance(acct_name = :default_account)  # use this instead of .new!! to get a singleton
        # TODO: solve bug related to running under puppet agent, where /var/lib/puppet/.hpcloud is being used instead of
        #       /root/.hpcloud 
        #      We might be able to work around this by setting ENV['HOME'] to a value like /opt/config/fog/.hpcloud
#        if @@connection_manager == nil
#          current_home = ENV['HOME']
#          ENV['HOME'] = '/opt/config/fog'
#          @@connection_manager = self.new(acct_name)
#          ENV['HOME'] = current_home
#        end
#        begin
#            FileUtils.cp_r "/var/lib/puppet/.hpcloud", "/root/.hpcloud", :verbose => true if File.exists?('/var/lib/puppet/.hpcloud')
#         rescue Exception => e
#            Puppet.crit "problem working around .hpcloud home #{e}"
#         end

        @@connection_manager ||= self.new(acct_name)
        return @@connection_manager
      end

      def initialize(acct_name = :default_account)
        Puppet.debug("creating new object Manager::HP::Connection")
        super(:hp)
        @options = {}
        @config = ::HP::Cloud::Config.new(true)
        @account_name = @config.get(acct_name)
        @account_name = acct_name.to_sym if @account_name == nil
        @accounts = ::HP::Cloud::Accounts.new()
        manage_connect
      end

      # we configure the cli to connect as necessary.
      def manage_connect
        Puppet.debug "calling manage_connect"
        @options = load_fog_options
        acct = setup_account

        @accounts.set_cred(@account_name, setup_creds(acct))
        # write to get catalog info
        @accounts.write(@account_name)

        avl1_zone_parts = []
        avl1_zone_parts = (@options[:hp_avl_zone] || @options[:avl_zone]).split('.')
        avl1_zone_parts.shift if ( avl1_zone_parts[0] =~ /^az(.*)/ )

        region = avl1_zone_parts.join('.')
        Puppet.debug("Manager::HP::Connection using region => #{region}")
        set_region(@accounts.read(@account_name), region)

        # validate these settings
        validate(@account_name)

        @accounts.write(@account_name)
        use_account(@account_name)
        Puppet.debug "done calling manage_connect"
      end

      def setup_account
        # create the account
        begin
          acct = @accounts.read(@account_name)
        rescue Exception => e
          acct = @accounts.create(@account_name)
        end
        
        acct[:provider] ||= 'hp'
        unless @options[:provider].nil?
          provider = @options[:provider].downcase
          if provider != acct[:provider]
            acct[:provider] = provider
            acct[:options] = {}
            acct[:credentials] = {}
            acct[:regions] = {}
          end
        end
        return acct
      end

      def validate(name)
        ::HP::Cloud::Accounts.new().read(name)
        Puppet.notice "Verifying '#{name}' account..."
        begin
          ::HP::Cloud::Connection.instance.validate_account(name)
          Puppet.notice "Able to connect to valid account '#{name}'."
        rescue Exception => e
          raise "Account verification failed. Please verify your account credentials. \n Exception: #{e}"
        end
      end

      def set_region(acct, region)
        cred = acct[:credentials]
        if cred[:auth_uri].nil?
          identifier = cred.to_s
        else
          identifier = cred[:auth_uri]
        end

        begin
          cata = ::HP::Cloud::Connection.instance.catalog(@account_name, [])
          regions = acct[:regions]
          if acct[:provider] == "hp"
            services = []
            cata.keys.each { |x| services << x.to_s }
            services.sort!
            services.each { |service|
              zone = "#{service.downcase}".to_sym
              regs = []
              cata[service.to_sym].keys.each { |x| regs << x.to_s }
              regs.sort!
              default_region = regions[zone] || regs.first.to_s
              az = regs.join(',')
              unless service == "Image Management" || service == "Identity"
                regions[zone] = region
              end
            }
          end
          acct[:regions] = regions
          @accounts.set_regions(@account_name, regions)
          @accounts.write(@account_name)
        rescue Exception => e
          # e = ErrorResponse.new(e).to_s
          raise "Setting up region failed. \n Exception: #{e}"
        end
      end

      def setup_creds(acct)
        # create the credential
        cred = acct[:credentials]
        service_name = "HP Cloud Services"
        unless @options[:userpass].nil?
          if @options[:userpass] == true
            cred[:userpass] = @options[:hp_userpass] || @options[:userpass]
          else
            cred[:userpass] = nil
          end
        end
        if cred[:userpass] == true
          cred[:account_id] = @options[:hp_account_id] || @options[:account_id]
          cred[:secret_key] = @options[:hp_userpass] || @options[:userpass]
        else
          cred[:account_id] = @options[:hp_access_key] || @options[:access_key]
          cred[:secret_key] = @options[:hp_secret_key] || @options[:secret_key]
        end
        cred[:tenant_id] = @options[:hp_tenant_id] || @options[:tenant_id]
        cred[:auth_uri] = @options[:hp_auth_uri] || @options[:auth_uri]
        return cred
      end

      def use_account(name)
        ::HP::Cloud::Accounts.new().read(name)
        @config.set(:default_account, name)
        @config.write()
      end
      
    end
  end
end

