/**
(c) Copyright 2014 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/**
* Global adapter config
*
* The `adapters` configuration object lets you create different global "saved settings"
* that you can mix and match in your models.  The `default` option indicates which
* "saved setting" should be used if a model doesn't have an adapter specified.
*
* Keep in mind that options you define directly in your model definitions
* will override these settings.
*
* For more information on adapter configuration, check out:
* http://sailsjs.org/#documentation
*/

module.exports.adapters = {

  // If you leave the adapter config unspecified
  // in a model definition, 'default' will be used.
  'default': 'disk',

  // Persistent adapter for DEVELOPMENT ONLY
  // (data is preserved when the server shuts down)
  disk: {
    module: 'sails-disk'
  },

  // MySQL is the world's most popular relational database.
  // Learn more: http://en.wikipedia.org/wiki/MySQL
  myLocalMySQLDatabase: {

    module: 'sails-mysql',
    host: 'YOUR_MYSQL_SERVER_HOSTNAME_OR_IP_ADDRESS',
    user: 'YOUR_MYSQL_USER',
    // Psst.. You can put your password in config/local.js instead
    // so you don't inadvertently push it up if you're using version control
    password: 'YOUR_MYSQL_PASSWORD',
    database: 'YOUR_MYSQL_DB'
  },

  maestroRedisDatabase: {

    module: 'sails-redis',
    port: process.env.REDIS_PORT || 6379,
    host: 'localhost',
    // db: process.env.REDIS_DB || 1,
    // database: process.env.REDIS_DB || 1,

    /**************************************************
    *  Due to a problem selecting the database
    *  in Redis using sails-redis adapter, the
    *  NotificationController.js do the select
    *  by itself.
    *  I think the problem is that the old
    *  version of sails-redis (0.9.x) doesn´t
    *  support that feature.
    *************************************************/
  },
};
