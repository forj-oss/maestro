# == Class: ::mysql_tuning
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
# Wrapper calls to mysql::server::config class
#
# What it does?
# (1) Creates a .cnf file at /etc/mysql/conf.d/
# (2) The values of step 1 overrides the values at /etc/mysql/my.cnf settings
# (3) Restarts mysql
#
# Parameters:
# key_buffer_size:      The value of key_buffer_size is the size of the buffer used with indexes.
#                       The larger the buffer, the faster the SQL command will finish and a result will be returned.
# table_open_cache:     Number of open tables for all threads.
# max_allowed_packet:   The maximum size of one packet or any generated/intermediate string.
# thread_stack:         The stack size for each thread.
# query_cache_limit:    Caches results until this limit.
# sort_buffer_size:     Each session that needs to do a sort allocates a buffer of this size.
# read_buffer_size:     Each thread that does a sequential scan for a MyISAM table allocates a buffer of this size for each table it scans.
# read_rnd_buffer_size: When reading rows from a MyISAM table in sorted order following a key-sorting operation,
#                       the rows are read through this buffer to avoid disk seeks.
# net_buffer_length:    Each client thread is associated with a connection buffer and result buffer.
#                       Both begin with a size given by net_buffer_length but are dynamically enlarged up to max_allowed_packet bytes as needed.
# join_buffer_size:     The minimum size of the buffer that is used for plain index scans, range index scans,
#                       and joins that do not use indexes and thus perform full table scans.

class mysql_tuning (
  $mysql_root_password  = hiera('mysql_tuning::mysql_root_password','changeme'),
  $key_buffer_size      = hiera('mysql_tuning::key_buffer_size','16K'),
  $table_open_cache     = hiera('mysql_tuning::table_open_cache','8'),
  $max_allowed_packet   = hiera('mysql_tuning::max_allowed_packet','1M'),
  $thread_stack         = hiera('mysql_tuning::thread_stack','128K'),
  $query_cache_limit    = hiera('mysql_tuning::query_cache_limit','2M'),
  $sort_buffer_size     = hiera('mysql_tuning::sort_buffer_size','64K'),
  $read_buffer_size     = hiera('mysql_tuning::read_buffer_size','256K'),
  $read_rnd_buffer_size = hiera('mysql_tuning::read_rnd_buffer_size','256K'),
  $net_buffer_length    = hiera('mysql_tuning::net_buffer_length','2K'),
  $join_buffer_size     = hiera('mysql_tuning::join_buffer_size','256K'),
)
{

  include mysql

  if !defined(Class['mysql::server'])
  {
    class { 'mysql::server':
      config_hash => { 'root_password' => $mysql_root_password }
    }
  }

  mysql::server::config { 'tuning':
    settings                   => {
      'mysqld'                 => {
        'key_buffer_size'      => $key_buffer_size,
        'table_open_cache'     => $table_open_cache,
        'max_allowed_packet'   => $max_allowed_packet,
        'thread_stack'         => $thread_stack,
        'query_cache_limit'    => $query_cache_limit,
        'sort_buffer_size'     => $sort_buffer_size,
        'read_buffer_size'     => $read_buffer_size,
        'read_rnd_buffer_size' => $read_rnd_buffer_size,
        'net_buffer_length'    => $net_buffer_length,
        'join_buffer_size'     => $join_buffer_size,
      }
    },
    require                    => Class['mysql::server'],
  }
}