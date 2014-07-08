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
# provide a method for caching facter results
module Puppet
  module Forj
    module Facter
      class Cache
        attr_accessor :config
        def self.instance(options = {})
          @@cache ||= self.new(options)
          return @@cache
        end

        #  initialize
        def initialize(options)
          @config = {
            :cache_dir => '/etc/puppet/facter.d',
            :ttl => 3600,
            :debug => false
            }.merge(external_options).merge(options) # hard coded options over ride all others
          # make sure cache_dir exist
          begin
            Dir.mkdir(@config[:cache_dir]) if !File::exists?(@config[:cache_dir])
          rescue Exception => e
            ::Puppet.crit "Facter::Cache failed to create #{@config[:cache_dir]}, Error: #{e}" if @config[:debug]
            raise ::Puppet::Error, "Error : #{e}"
          end
          if !(defined?(::Puppet)).nil?
            @config[:debug] = false # force no Puppet calls when we can't find a Puppet object
          end
        end

        # load external options from facters first then env second
        # env overwrites facters
        def external_options
          options = {}
          # default facters first
          begin
            if !(defined?(::Facter)).nil?
              options[:cache_dir] = ::Facter.value('facter_cache_dir') if ::Facter.value('facter_cache_dir') != nil and ::Facter.value('facter_cache_dir') != ''
              options[:ttl] = ::Facter.value('facter_cache_ttl').to_i if ::Facter.value('facter_cache_ttl') != nil and ::Facter.value('facter_cache_ttl') != ''
            end
          rescue
          end
          
          begin
            options[:cache_dir] = ENV['FACTER_CACHE_DIR'] if ENV['FACTER_CACHE_DIR'] != nil and ENV['FACTER_CACHE_DIR'] != ''
            options[:ttl] = ENV['FACTER_CACHE_TTL'].to_i if ENV['FACTER_CACHE_TTL'] != nil and ENV['FACTER_CACHE_TTL'] != ''
            options[:debug] = true if ENV['FACTER_DEBUG'] == 'true'
          rescue
          end
          return options
        end

        # read cache value
        def read( name )
          value = String.new
          time = nil
          begin
            fspec = File.join(@config[:cache_dir], "#{name}.json")
            if File.exist?( fspec )
              File.open( fspec , "r" ) do |f|
                value = JSON.load( f )
                time = File.mtime( fspec )
                ::Pupppet.debug "reading cache for #{name} => #{value}" if config[:debug]
              end
            else
              ::Pupppet.debug "No cache found for #{name}" if @config[:debug]
              time = Time.at(0)
              value = nil
            end
          rescue Exception => e
            ::Puppet.warn "unable to read from cache #{name}, #{e}" if @config[:debug]
          end
          return {:data => value, :time => time }
        end

        # write cache value
        def write(name, value)
          begin
            File.open(File.join(@config[:cache_dir], "#{name}.json"),"w") do |f|
              f.write(value.to_json)
            end
          rescue Exception => e
            ::Puppet.warn "unable to write #{name} for #{value}, #{e}" if @config[:debug]
          end
          return value
        end

        # cache values if ttl expired
        def cache(name, &block)
          data = nil
          begin
            cache_data = nil
            begin
              cache_data = read(name)
            rescue
              cache_data = { :data => data, :time => Time.at(0) } # no cache
            end
            if ! cache_data[:data]        ||
                 cache_data[:data] == nil ||
                 cache_data[:data] == ''  ||
                 cache_data[:data].to_sym == :undefined || (Time.now - cache_data[:time]) > @config[:ttl]
              begin
                data = block.call
                write(name, data)
                ::Puppet.debug "wrote cache for #{name} => #{data}" if @config[:debug]
              rescue Exception => e
                ::Puppet.warn "failed to get facter value for cache, #{e}"
              end
            else
              data = cache_data[:data]
              ::Puppet.debug "using cache for #{name} => #{data}" if @config[:debug]
            end
          rescue Exception => e
            ::Puppet.warn "failed to cache data for cache" if @config[:debug]
          end
          return data
        end
        
      end
    end
  end
end
