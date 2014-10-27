# == Define: nodejs_wrap::pm2instance
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
#
# Creates a service at /etc/init.d and
# runs a jsnode app using PM2 npm package
#
# === Parameters
#
# [*ensure*]  absent or present
#   Configure/unconfigure nodejs instance
#
# [*pm2name*]  defaults to title but can be anything
#   The app name that appears on pm2 list
#
# [*user*]
#   User that runs nodejs
#
# [*script_dir*]
#   Nodejs Application root directory
#
# [*script*]
#   Script to run
#
# [*node_path*]
#   nodejs modules path
#
# Example run: puppet apply -e "nodejs_wrap::pm2instance{'kitops': ensure => 'present', user => 'puppet', script_dir => '/opt/config/production/app/forj.config', script => 'kitops.js', node_path => '/usr/lib/node_modules', }" --modulepath=/opt/config/production/git/maestro/puppet/modules:/etc/puppet/modules --verbose
#
define nodejs_wrap::pm2instance(
  $script               = $title,
  $pm2name              = $title,
  $ensure               = hiera('nodejs_wrap::ensure', 'present'),
  $user                 = hiera('nodejs_wrap::user', 'puppet'),
  $instance             = '1',
  $script_dir           = undef,
  $node_path            = hiera('nodejs_wrap::node_path', '/usr/lib/node_modules'),
  $node_env             = hiera('nodejs_wrap::node_env', 'development'),
  $do_local_npm_install = true,
) {
  require nodejs_wrap
  include nodejs_wrap::pm2service

  if $script_dir == undef {
    fail('ERROR! nodejs_wrap::pm2instance::script_dir is undef')
  }
  case $ensure {
      'present': {
              exec { "${script_dir}-chmod" :
                command     => "chmod 0755 -R ${script_dir}",
                path        => $::path,
              }
              exec { "${script_dir}-chown" :
                command     => "chown -R ${user}:${user} ${script_dir}",
                path        => $::path,
              }
              # handle the defaults
              $node_environment = ["NODE_PATH=${node_path}" , "NODE_ENV=${node_env}"]
              # handle setting HTTP_PROXY
              $http_host = inline_template('<%= (ENV["HTTP_PROXY"] == nil) ? nil : URI.parse(ENV["HTTP_PROXY"]).host %>')
              $http_port = inline_template('<%= (ENV["HTTP_PROXY"] == nil) ? nil : URI.parse(ENV["HTTP_PROXY"]).port %>')
              if $http_host != '' and $http_host != undef
              {
                $http_proxy_host = ["HTTP_PROXY_HOST=${http_host}"]
              } else
              {
                $http_proxy_host = []
              }
              if $http_port != '' and $http_port != undef
              {
                $http_proxy_port = ["HTTP_PROXY_PORT=${http_port}"]
              } else
              {
                $http_proxy_port = []
              }
              # handle setting HTTPS_PROXY
              $https_host = inline_template('<%= (ENV["HTTPS_PROXY"] == nil) ? nil : URI.parse(ENV["HTTPS_PROXY"]).host %>')
              $https_port = inline_template('<%= (ENV["HTTPS_PROXY"] == nil) ? nil : URI.parse(ENV["HTTPS_PROXY"]).port %>')
              if $https_host != '' and $https_host != undef
              {
                $https_proxy_host = ["HTTPS_PROXY_HOST=${https_host}"]
              } else
              {
                $https_proxy_host = []
              }
              if $https_port != '' and $https_port != undef
              {
                $https_proxy_port = ["HTTPS_PROXY_PORT=${https_port}"]
              } else
              {
                $https_proxy_port = []
              }
              # combine them all to make pm2instance_environment
              $pm2instance_environment = split(inline_template('<%= (@node_environment + @http_proxy_host + @http_proxy_port + @https_proxy_host + @https_proxy_port).join(\',\') %>'),',')
              debug("using environment for pm2instance => ${pm2instance_environment}")

              if $do_local_npm_install == true {
                $pm2_require = [ Package['pm2'], Exec["${script_dir}-chmod"], Exec["${script_dir}-chown"], Exec["npm install of ${pm2name}"] ]
                exec { "npm install of ${pm2name}":
                  command     => 'npm install',
                  environment => $pm2instance_environment,
                  path        => $::path,
                  cwd         => $script_dir,
                }
              }else{
                $pm2_require = [ Package['pm2'], Exec["${script_dir}-chmod"], Exec["${script_dir}-chown"] ]
              }
              exec { "${ensure} pm2 script ${pm2name}":
                command     => "pm2 start '${script}' -n ${pm2name} -u ${user} -i ${instance} --run-as-user ${user} --run-as-group ${user}",
                cwd         => $script_dir,
                environment => $pm2instance_environment,
                path        => $::path,
                require     => $pm2_require,
                onlyif      => "test \$(pm2 status > /dev/null;pm2 list|grep ${pm2name}|grep online|wc -l) -eq 0",
                logoutput   => true,
              }

              # pm2 0.8.2 issues with node 0.11.13
              # exec { "${ensure} pm2 script ${pm2name}":
              #   command     => "${command} ${script_dir}/${script} &",
              #   cwd         => $script_dir,
              #   environment => ["NODE_PATH=${node_path}", "NODE_ENV=${node_env}"],
              #   path        => ['/bin','/usr/bin'],
              #   unless      => "ps aux | grep ${script} | grep -v grep",
              #   require     => File[$script_dir],
              #   logoutput   => true,
              # }
      }
      'absent': {
              exec { "${ensure} pm2 script ${pm2name}":
                command     => "pm2 delete ${pm2name}",
                cwd         => $script_dir,
                environment => ["HOME=/home/${user}" , "NODE_PATH=${node_path}", "NODE_ENV=${node_env}"],
                path        => $::path,
                require     => [ Package['pm2']],
                onlyif      => "test \$(pm2 status > /dev/null;pm2 list|grep ${pm2name}|grep online|wc -l) -eq 0",
                user        => $user,
              }
      }
      default: {
        fail('pm2instance accepts ensure => present or absent.')
      }
  }
}
