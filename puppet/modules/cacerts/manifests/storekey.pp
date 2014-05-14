# == cacerts::storekey
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
# store ssh keys on puppet master
#

define cacerts::storekey (
  $key_spec   = $title,
  $contents   = undef,
)
{
  include cacerts::params
  if ($contents != undef)
  {
    cacerts_storekey("${cacerts::params::ssh_keys_dir}/${key_spec}", $contents)
  } else
  {
    fail("Key to store was empty, ${key_spec}.")
  }
}
