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
require 'rubygems'
require 'fog'

Puppet::Type.type(:object_storage).provide(:hp) do
    desc "Handles HP Cloud - Object Storage"
    
    # TODO: ChL: This file has currently not been updated related to credentials. But normally, any fog task uses /root/.fog. credentials should not exist in puppet files anymore.
    def getCredentials()
      credentials = {}
          
      @resource[:credentials].each do |key, item|
      case key
      
        when :provider
          credentials[:provider] = item
        when :hp_access_key
          credentials[:hp_access_key] = item
        when :hp_secret_key
          credentials[:hp_secret_key] = item
        when :hp_tenant_id
          credentials[:hp_tenant_id] = item            
        when :hp_auth_uri
          credentials[:hp_auth_uri] = item            
        when :hp_avl_zone
          credentials[:hp_avl_zone] = item                        
        end
      
      end           
      
      return credentials      
      
    end

    def create

      conn = Fog::Storage.new(getCredentials())
             
      #puts @resource[:credentials]      
      puts "Connection created"           
            
      #p conn.directories     
      
      dir = conn.directories.get(@resource[:remote_dir])           
      
      if dir.nil?
        #Create a directory     
        dir = conn.directories.create(
            :key    => @resource[:remote_dir], # globally unique name
            :public => true
        )     
        puts "Directory created"                 
        dir = conn.directories.get(@resource[:remote_dir])
      end
      
      puts "Uploading #{@resource[:local_dir]}/#{@resource[:file_name]} to #{@resource[:remote_dir]}"

      #Upload a file              
      file = dir.files.create(
        :key    => @resource[:file_name],
        :body   => File.open("#{@resource[:local_dir]}/#{@resource[:file_name]}"),
        :public => true
      )      
      puts "File uploaded"                                      
    end

    
    
    def destroy
      conn = Fog::Storage.new(getCredentials())
      
      puts "Deleting file"
      dir = conn.directories.get(@resource[:remote_dir])
      
      if dir.nil?
        puts "Directory doesn't exist"             
      else        
        file = dir.files.get(@resource[:file_name])
        if file.nil?
            puts "File doesn't exist"
        else 
            file.destroy
            puts "Deleted" 
        end             
      end
              
      # chaining a series of calls to delete a file
      #conn.directories.get("fog-rocks").files.get("another-sample.txt").destroy
    end

    
    
    def exists?
      
      r = false
      conn = Fog::Storage.new(getCredentials())

      #Verify if a file exists
      dir = conn.directories.get(@resource[:remote_dir])           
      
      if dir.nil?
        puts "Directory doesn't exist"             
      else        
        file = dir.files.get(@resource[:file_name])
        if file.nil?
            puts "File doesn't exist"
        else 
            r = true  
        end             
      end
      
      return r                                     
    end
end