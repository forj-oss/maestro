# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
# helper functions for config.json parser
# crup = cr=create , up=update
require 'json'
require 'fileutils'

module Puppet
  class CrupHelper
    # accessors
    attr_accessor :config_json_spec
    attr_reader   :tool_name
    attr_reader   :node_name
    attr_accessor :tool_properties
    attr_accessor :tool_values
    attr_accessor :site_data
    attr_accessor :puppetobj
    attr_accessor :initalized

    def initialize(
      tool          = nil,
      name          = 'default',
      properties    = [],
      values        = [],
      default_tools = [],
      filter_tools  = [],
      puppet        = nil,
      create_config = true
    )
       @initalized = false
       @puppetobj = puppet
       @config_json_spec = (@puppetobj != nil ) ? @puppetobj.lookupvar('::json_config_location') : nil
       if name == nil || name == ""
          @node_name = "default"
       else
          @node_name = name
       end
       @tool_name         = tool
       @tool_properties   = properties
       @tool_values       = values
       @site_data         = nil

      owner = (@puppetobj != nil ) ? @puppetobj.lookupvar('json_config_user') : ''
      owner = 'puppet' if owner == '' || owner == nil || owner == :undefined

      group = (@puppetobj != nil ) ? @puppetobj.lookupvar('maestro_ui_owner') : ''
      group = 'ubuntu' if group == '' || group == nil || group == :undefined
      @config_json_owner = owner
      @config_json_group = group
      @default_tools     = default_tools

      raise(Puppet::ParseError, "facter value ::json_config_location is missing, config.json needs a path.") if @config_json_spec == nil || @config_json_spec == ''
      return nil if (!File.exists?(@config_json_spec) and create_config == false)
      initialize_crup_data(@default_tools - filter_tools) unless File.exists?(@config_json_spec)
      load_data
      @initalized = true
    end
    def is_initialized?
      return @initalized
    end
    #save the json string to a file
    def save_file(data, fspec = @config_json_spec)
      does_fileexist = File.exists?(fspec)
      File.open(fspec, "w") do |file|
        Puppet.debug "saving file #{fspec}"
        file.puts JSON.pretty_generate(data)
        # we want to set the initial permissions only if we're creating the file
        file.chmod(0664) unless does_fileexist
      end
      FileUtils.chown @config_json_owner, @config_json_group, fspec unless does_fileexist
    end

    # save to current @config_json_spec
    def save(fspec = @config_json_spec, options = {})
      data = JSON.parse(@site_data.to_json)
      show_json_debug("2", data)
      self.save_file(data, fspec)
      if options[:owner] != ""
        if options[:group] != ""
          FileUtils.chown options[:owner], options[:group], fspec
        else
          FileUtils.chown options[:owner], options[:owner], fspec
        end
      end
    end

    # manage site information for blueprint name
    def set_sitekey( keyname, keyvalue)
      if sitekey_exist? keyname
        @site_data["site"][keyname] = keyvalue
      end
    end

    def sitekey_exist?( keyname )
       return @site_data["site"].has_key?(keyname)
    end

    def add_sitekey(keyname, defval = nil)
      @site_data["site"][keyname]  = defval
    end

    # add the node if it doesn't exist
    def add_node
      return if @node_name == nil
      unless node_exist?
        tool_hash = Hash[@tool_properties.zip @tool_values]
        new_node = {
          "node_name" => @node_name,
          "tools"     => [
            tool_hash
          ]
        }
        @site_data["site"]["node"] << new_node
      end
    end

    def add_tool
      return if @tool_name == nil
      tools = get_tools
      tool_hash = Hash[@tool_properties.zip @tool_values]
      if tool_exist?
        tools.each_with_index do |tool, i|
          tools[i] = tool_hash if tool["name"] == @tool_name  # update
        end
      else
        tools << tool_hash
      end
      set_tools(tools)
    end

    # check to see if tool exist on node
    def tool_exist?
      get_tools.each do |tool|
        return true if tool["name"] == @tool_name
      end
      return false
    end

    # set the tools array on the node
    def set_tools(tools)
      @site_data["site"]["node"].each do | node |
        node["tools"] = tools if node["node_name"] == @node_name
      end
    end

    # get the tool from the node
    def get_tools
      @site_data["site"]["node"].each do | node |
        return node["tools"] if node["node_name"] == @node_name
      end
      return []
    end

    # exist node?
    def node_exist?
      @site_data["site"]["node"].each do | node |
        return true if node["node_name"] == @node_name
      end
      return false
    end

    # remove default node for tool
    def remove_default_tool
      
      index_node = 0
      @site_data["site"]["node"].each do | node |
        if node["node_name"] =~ /^default.*/
          index_tool = 0
          node["tools"].each do | tools |
            if tools["name"] == @tool_name
              @site_data["site"]["node"][index_node]["tools"].delete_at(index_tool)
            end
            index_tool = index_tool + 1
          end
        end
        index_node = index_node + 1
      end
      @site_data = remove_empty_default_nodes(@site_data)
    end

    # load data
    def load_data
      raise(Puppet::ParseError, "unable to continue, no json data to load in #{@config_json_spec}.") unless File.exists?(@config_json_spec)
      @site_data = JSON.parse(File.read(@config_json_spec))
    end

    def lookupvar_exist(param = '')
      return false if @puppetobj == nil and  param == ''
      return (@puppetobj.lookupvar(param) != '' and
              @puppetobj.lookupvar(param) != :undefined and
              @puppetobj.lookupvar(param) != nil)
    end
    private


    # initialize an empty data structure for crup
    def initialize_crup_data(default_tools = [])
      # TODO: need a way to discover all the tools that have facts for jimador
      tools = []
      default_tools.each do | tool_name |
        tools << {
          :dname         => tool_name,
          :desc          => "",
          :status        => "offline",
          :tool_url      => "#",
          :settings_url  => "#",
          :name          => tool_name,
          :category      => "dev",
          :icon          => "false",
          :visible       => "true",
          :statistics    => "false",
        }
      end if default_tools.kind_of?(Array)

      default_node = {
        :node_name => "default",
        :tools     => tools
      }
      json_data = {
                    :site      => { "node" => [ default_node ],
                                     :id        => lookupvar_exist('maestro_id')        ? @puppetobj.lookupvar('maestro_id') : '', # we try to get the defaults from facter
                                     :blueprint => lookupvar_exist('maestro_blueprint') ? @puppetobj.lookupvar('maestro_blueprint') : '',
                                     :projects  => lookupvar_exist('maestro_projects')  ? @puppetobj.lookupvar('maestro_projects') : 'false',
                                     :users     => lookupvar_exist('maestro_users')     ? @puppetobj.lookupvar('maestro_users') : 'false',
                                  }
                  }
      @site_data = JSON.parse(json_data.to_json) if @site_data == nil
      add_node
      data = JSON.parse(@site_data.to_json)
      show_json_debug("1", data)
      self.save_file(data)
    end


    # trouble shoot where we have problems.
    def show_json_debug(section, data)
      Puppet.debug "in debug #{section}"
      Puppet.debug JSON.pretty_generate(data).to_s
    end

    # remove any empty nodes
    def remove_empty_default_nodes(jsondata)

      index_node = 0
      jsondata["site"]["node"].each do | node |
        if node["node_name"] =~ /^default.*/
          if node["tools"].length <= 0
            jsondata["site"]["node"].delete_at(index_node)
          end
        end
        index_node = index_node + 1
      end
      return jsondata
    end
  end
end