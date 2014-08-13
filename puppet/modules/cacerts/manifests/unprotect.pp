# == cacerts::unprotect
#
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
# remove password from key
#
define cacerts::unprotect(
  $certs_dir  = $title,
  $pass       = '',
  $ext        = 'locked_key',
)
{
  if $pass != '' or $pass != undef
  {
    exec { "un-protect for root:: ${certs_dir} ":
      path    => ['/bin', '/usr/bin'],
      command => "find ${certs_dir} -name '*.${ext}'|xargs -i basename {} .${ext}|xargs -i openssl rsa -passin pass:${pass} -in {}.${ext} -out {}.key",
      cwd     => $certs_dir,
      onlyif  => [
                  'test -f /usr/bin/openssl',
                  "test -d ${certs_dir}"
                  ],
      user    => 'root',
    }
  } else
  {
    warning("skip run for cacerts::unprotect due to empty password passed for ${certs_dir}")
  }
}
