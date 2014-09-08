# == Class: redis::params
#
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
# see http://redis.io/topics/memory-optimization
# see http://redis.io/topics/latency
# see http://www.fabrizio-branca.de/redis-optimization.html
class redis::params {

  #lets use the ppa instead
  $manage_repo                 = hiera('redis::params::manage_repo',false)

  $activerehashing             = hiera('redis::params::activerehashing',true)
  $appendfsync                 = hiera('redis::params::appendfsync','everysec')
  $appendonly                  = hiera('redis::params::appendonly',false)
  $auto_aof_rewrite_min_size   = hiera('redis::params::auto_aof_rewrite_min_size','64min')
  $auto_aof_rewrite_percentage = hiera('redis::params::auto_aof_rewrite_percentage',100)
  $bind                        = hiera('redis::params::bind','127.0.0.1')
  $conf_template               = hiera('redis::params::conf_template','redis/redis.conf.erb')
  $daemonize                   = hiera('redis::params::daemonize',true)
  $databases                   = hiera('redis::params::databases',16)
  $dbfilename                  = hiera('redis::params::dbfilename','db-dump.rdb')
  $extra_config_file           = hiera('redis::params::extra_config_file',false)
  $hash_max_ziplist_entries    = hiera('redis::params::hash_max_ziplist_entries',512)
  $hash_max_ziplist_value      = hiera('redis::params::hash_max_ziplist_value',64)
  $list_max_ziplist_entries    = hiera('redis::params::list_max_ziplist_entries',512)
  $list_max_ziplist_value      = hiera('redis::params::list_max_ziplist_value',64)
  $log_dir                     = hiera('redis::params::log_dir','/var/log/redis')
  $log_file                    = hiera('redis::params::log_file','/var/log/redis/redis.log')
  $log_level                   = hiera('redis::params::log_level','notice')
  #lets play/tune with this...default is 10k, but that is a bit much
  $maxclients                  = hiera('redis::params::maxclients',1000)
  $maxmemory                   = hiera('redis::params::maxmemory',false)
  $maxmemory_policy            = hiera('redis::params::maxmemory_policy',false)
  $maxmemory_samples           = hiera('redis::params::maxmemory_samples',false)
  $no_appendfsync_on_rewrite   = hiera('redis::params::no_appendfsync_on_rewrite',false)
  $pid_file                    = hiera('redis::params::pid_file','/var/run/redis/redis-server.pid')
  $port                        = hiera('redis::params::port',6379)
  $rdbcompression              = hiera('redis::params::rdbcompression',true)
  $requirepass                 = hiera('redis::params::requirepass',false)
  $set_max_intset_entries      = hiera('redis::params::set_max_intset_entries',512)
  $slowlog_log_slower_than     = hiera('redis::params::slowlog_log_slower_than',10000)
  $slowlog_max_len             = hiera('redis::params::slowlog_max_len',1024)
  $syslog_enabled              = hiera('redis::params::syslog_enabled',false)
  $syslog_facility             = hiera('redis::params::syslog_facility',false)
  $timeout                     = hiera('redis::params::timeout',0)
  # TODO: am wondering about this param...
  $ulimit                      = hiera('redis::params::ulimit',65536)
  $workdir                     = hiera('redis::params::workdir','/var/lib/redis/')
  $zset_max_ziplist_entries    = hiera('redis::params::zset_max_ziplist_entries',128)
  $zset_max_ziplist_value      = hiera('redis::params::zset_max_ziplist_value',64)

  #replication
  $masterauth                  = hiera('redis::params::masterauth',false)
  $repl_ping_slave_period      = hiera('redis::params::repl_ping_slave_period',10)
  $repl_timeout                = hiera('redis::params::repl_timeout',60)
  $slave_read_only             = hiera('redis::params::slave_read_only',true)
  $slave_serve_stale_data      = hiera('redis::params::slave_serve_stale_data',true)
  $slaveof                     = hiera('redis::params::slaveof',false)

  case $::osfamily {
    'Debian': {
      $config_dir         = '/etc/redis'
      $config_dir_mode    = '0755'
      $config_file        = '/etc/redis/redis.conf'
      $config_file_mode   = '0644'
      $config_group       = 'root'
      $config_owner       = 'root'
      $package_ensure     = 'present'
      $package_name       = 'redis-server'
      $service_enable     = true
      $service_ensure     = 'running'
      $service_group      = 'redis'
      $service_hasrestart = true
      $service_hasstatus  = false
      $service_name       = 'redis-server'
      $service_user       = 'redis'
      $ppa_repo           = 'ppa:chris-lea/redis-server'
    }

    default: {
      fail ("Operating system ${::operatingsystem} is not supported yet.")
    }
  }
}
