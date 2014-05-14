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
# actions that the custom type will take
module Pinas
  module Compute
    module Actions
      # create a new server
      def create
          #TODO: network_name should be defaulted, but we havn't found how to do that in a type definition.
          @loader = ::Pinas::Compute::Provider::Loader
          @computeservice = ::Pinas::Compute::Provider::Compute
          pinas = @computeservice.instance(@loader.get_compute, @loader.get_network(@resource[:server_template]))
          
          do_threaded = pinas.to_bool(@resource[:do_parallel].to_s)
          delay = @resource[:delay]
          sleep(delay.to_i) if delay != nil and delay.to_i > 0
          if do_threaded
            thread_creates = []
            @resource[:nodes].each do |server|
              thread_creates << Thread.new do
                begin
                  server_name = get_servername(server)
                  server_found = pinas.server_exist?(server_name)
                  pinas.server_create(server_name, @resource[:server_template]) if !server_found
                rescue Exception::Error => e
                  raise Puppet::Error, "Error : #{e}"
                end
              end
            end
            thread_creates.each do |tcreate|
              tcreate.join
            end
          else
            @resource[:nodes].each do |server|
              begin
                server_name = get_servername(server)
                server_found = pinas.server_exist?(server_name)
                pinas.server_create(server_name, @resource[:server_template]) if !server_found
              rescue Exception::Error => e
                raise Puppet::Error, "Problem with server_create: #{e}"
              end
            end
          end
          Puppet.debug "done with create"
      end
  
    # destroy an existing server
      def destroy
          @loader = ::Pinas::Compute::Provider::Loader
          @computeservice = ::Pinas::Compute::Provider::Compute
          network_name = @loader.get_network_name(@resource[:server_template])
          @networkservice = (network_name != nil ) ? @loader.get_network(@resource[:server_template]) : nil
          pinas = @computeservice.instance(@loader.get_compute, @networkservice) 
          
          do_threaded = pinas.to_bool(@resource[:do_parallel].to_s)
          if do_threaded
            thread_destroys = []
            @resource[:nodes].each do |server|
              thread_destroys << Thread.new do
                begin
                  server_name = get_servername(server)
                  pinas.server_destroy(server_name)
                rescue Exception::Error => e
                  raise Puppet::Error, "Error : #{e}"
                end
              end
            end
            thread_destroys.each do |tdestroy|
              tdestroy.join
            end
          else
            @resource[:nodes].each do |server|
              begin
                server_name = get_servername(server)
                pinas.server_destroy(server_name)
              rescue Exception::Error => e
                raise Puppet::Error, "Problem with server_destroy: #{e}"
              end
            end
          end
          Puppet.debug "done with destroy"
      end
  
    # check if a server exist
      def exists?
         # TODO: network_name should be defaulted, but we havn't found how to do that in a type definition.
        @loader = ::Pinas::Compute::Provider::Loader
        @computeservice = ::Pinas::Compute::Provider::Compute
        network_name = @loader.get_network_name(@resource[:server_template])
        @networkservice = (network_name != nil ) ? @loader.get_network(@resource[:server_template]) : nil
        pinas = @computeservice.instance(@loader.get_compute, @networkservice)
  
        Puppet.notice "checking if nodes #{@resource[:nodes]} exist."
  
        @resource[:nodes].each do |server|
            server_name = get_servername(server)
            server_found = pinas.server_exist?(server_name)
            return false if !server_found
        end
         Puppet.notice "all nodes found, for instance : #{@resource[:instance_id]}"
         return true
      end
  
    end
  end
end
  
