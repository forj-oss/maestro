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
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

module Puppet
  module Forj
    class UtilURI
      # TODO: had to move this here because String implementation in forj_common
      # wasn't getting picked up.. Need to investiate how to extend this class.
      def rchomp(spec, sep = $/)
        spec.start_with?(sep) ? spec[sep.size..-1] : spec
      end
      ## get proxy from environment
      def getproxy
        proxy = (ENV['HTTP_PROXY'] == nil)? ENV['http_proxy'] : ENV['HTTP_PROXY']
        return proxy
      end
      #
      ## get proxy settings from environment variables we expect
      ##
      def getproxyuri
         proxy = self.getproxy
         proxy_uri = (proxy != nil )? URI.parse(proxy) : nil
         return proxy_uri
      end
    
      ## open a url and return the data
      def openurl(url, code = '200', use_proxy = true, timeout = 5)
        data = nil
        uri = URI.parse(url)
        proxy_uri = nil
        proxy_uri = self.getproxyuri if use_proxy
        debug("#{uri.host} #{uri.port} #{proxy_uri.host} #{proxy_uri.port}") if proxy_uri != nil
        debug("#{uri.host} #{uri.port}") if proxy_uri == nil
        http = (proxy_uri != nil) ? Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port) : Net::HTTP.new(uri.host, uri.port)
        save_timeout = http.read_timeout
        http.read_timeout = timeout # provide a short timeout for facter
        if uri.scheme == "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        begin
          http.start {
            http.request_get(uri.path) {|res|
              debug("res code = #{res.code}")
              data = res.body if res.code == code
            }
          }
        rescue Timeout::Error => detail
          http.read_timeout = save_timeout  # reset the timeout that it was before
          raise(Timeout::Error, detail)
        end
        http.read_timeout = save_timeout
        return data
      end
      def open_jsonurl(url, code = '200', use_proxy = true, timeout = 5)
        data = self.openurl(url, code, use_proxy, timeout)
        if data != '' and data != nil
          data.gsub!('\'', '"')
          data.gsub!('\"', '"')
          data = rchomp(data, '"').chomp('"')
          json = JSON.parse(data)
          return json
        else
          return nil
        end
      end
    end
  end
end
