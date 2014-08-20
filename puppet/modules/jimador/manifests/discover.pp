# == Class: jimador::discover
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

define jimador::discover (
  $node          = $title,
  $tools        = ['gerrit','pastebin','jenkins','zuul','puppet','graphite','status'],
  $tools_filter = [],
  $tools_data   = undef,
)
{
  include jimador::requirements   # this will install json for us
  if $tools_data != undef
  {
    jimador::manage_config { $tools:
      tools_hash    => $tools_data,
      node_name     => $node,
      default_tools => $tools,
      filter_tools  => $tools_filter,
    }
  }
}