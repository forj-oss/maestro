# == Class: jimador::write_sitekeys
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
# handle writing multiple site keys
define jimador::write_sitekeys (
  $property_name = $title,
  $data   = undef,
)
{
  if $data == undef
  {
    fail('jimador::write_sitekeys requires a data attribute')
  }
  $key_val = $data[$property_name]
  if !defined(Jimador::Write_config_yaml[$property_name])
  {
    jimador::write_config_yaml { $property_name:
        data => $key_val,
        type => 'site',
    }
  }

}