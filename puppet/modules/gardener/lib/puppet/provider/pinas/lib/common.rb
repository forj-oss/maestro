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
# common implementation class for server management under pinas
# TODO:  convert most of these methods into Manager::Connection::HP class.



module Pinas
  module Common
    # credit: http://www.goodercode.com/wp/convert-your-hash-keys-to-object-properties-in-ruby/
    class ::Hash
      def method_missing(name)
        return self[name] if key? name
        self.each { |k,v|
          k = 'hash_id' if k.to_s == 'id' # avoid depricated object error
          k = 'hash_type' if k.to_s == 'type' # avoid depricated object error
          return v if k.to_s.to_sym == name 
        }
        super.method_missing name
      end
    end
    # find a collection match
    def find_match(collection, name, multimatch = false)
      Puppet.debug "inspecting collection #{collection.length} for #{name}"
      found = []
      collection.each do |single|
        is_found = false
        if single.is_a?(Hash)
          is_found = ((single != nil ) && (single.hash_id.to_s == name.to_s || single.name == name  || name.is_a?(Regexp) && name =~ single.name ))
        else
          is_found = ((single != nil ) && (single.id.to_s == name.to_s || single.name == name  || name.is_a?(Regexp) && name =~ single.name ))
        end
        found << single if is_found
        return single if (multimatch == false && found.length > 0)
      end
      Puppet.debug "matches found = #{found.length}"
      return (found.length > 0) ? found : nil
    end

    def get_servername(server)
      if @resource[:instance_id] == ''
        return server
      else
        return "#{server}.#{@resource[:instance_id]}"
      end
    end

    #TODO: methods below here need to be moved to a manager class.
    # get the connection options
    def get_connection_options()
      proxy = (ENV['HTTP_PROXY'] == nil)? ENV['http_proxy'] : ENV['HTTP_PROXY']
      timeout = (ENV['FOG_TIMEOUTS'] == nil)? ENV['fog_timeout'] : ENV['FOG_TIMEOUTS']
      fog_debug = (ENV['FOG_DEBUG'] == nil)? ENV['fog_debug'] : ENV['FOG_DEBUG']
      options = {}
      options[:instrumentor] = Excon::StandardInstrumentor if fog_debug != nil
      if timeout != nil
       options[:connect_timeout] = timeout
       options[:read_timeout]    = timeout
       options[:write_timeout]   = timeout
      end 
      if proxy != nil
        options[:proxy] = proxy
        #TODO: investigate ssl cert verify
        uri = URI.parse(proxy)
        if uri.scheme == "https"
          options[:ssl_verify_peer] = false
        end
      end 
      return options
    end

    # parse the zone from fqdn
    def parse_zone(fqdn)
      return fqdn.sub("#{fqdn.split('.').shift}.","")
    end
    # check if a value is numeric
    def is_numeric?(val)
      begin
        res = true if Float val
      rescue
        res = false
      end
      return res
    end
    # check if a value is a boolean
    def to_bool(val)
        return true if val == true || val =~ (/(true|t|yes|y|1)$/i)
        return false if val == false || val =~ (/(false|f|no|n|0)$/i)
        raise ArgumentError.new("invalid value for Boolean: \"#{val}\"")
    end
  end
end
  
