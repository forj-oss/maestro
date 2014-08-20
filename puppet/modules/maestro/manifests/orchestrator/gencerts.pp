# == Class: ::maestro::orchestrator::gencerts.
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


# gen cacerts
define maestro::orchestrator::gencerts (
    $domain,
    $site_name   = $title,
    $instance_id = '',
    $serial_init = '01'
)
{
  include cacerts
  if ($instance_id == '')
  {
    $site = $site_name
  }
  else
  {
    $site = "${site_name}.${instance_id}"
  }
  cacerts::master_make_keys{ $site :
    domain      => $domain,
    serial_init => $serial_init,
  }
}

