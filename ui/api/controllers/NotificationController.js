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
* RedisController
*
* @module      :: Controller
* @description	:: A set of functions called `actions`.
*
*                 Actions contain code telling Sails how to respond to a certain type of request.
*                 (i.e. do stuff, then send some JSON, show an HTML page, or redirect to another URL)
*
*                 You can configure the blueprint URLs which trigger these actions (`config/controllers.js`)
*                 and/or override them with custom routes (`config/routes.js`)
*
*                 NOTE: The code you write here supports both HTTP and Socket.io automatically.
*
* @docs        :: http://sailsjs.org/#!documentation/controllers
*/

'use strict';
var async = require('async');
var getRedisNotificationDB = function () {
  return sails.config.env.backend.db.redis.id || 1;
};

module.exports = {


  index: function (req, res) {

    if (!req.session.email) {
      return res.json({
        success: false,
        error: 'You must be logged in.'
      });
    }

    var param = req.session.email + '*';

    async.waterfall([function(callback) {
      Notification.native(callback);
    },
    function(collection, callback) {// Selects redis database
      collection.select(getRedisNotificationDB(), function(err) {
        callback(err, collection);
      });
    },
    function(collection, callback) {// Gets all the user's keys
      collection.keys(param, function(err, keys) {
        callback(err, collection, keys);
      });
    },
    function(collection, keys, callback) {// Gets the value of each key
      var result = [];
      async.each(keys, function(key, cb) {

        collection.get(key, function (err, buffer) {
          if (err) {
            return cb(err);
          }

          buffer = JSON.parse(buffer);
          buffer.id = key;
          result.push(buffer);
          cb();
        });
      }, function(err) {
        callback(err, result);
      });
    }],
    function(err, result) {

      if (err) {
        return console.log(err);
      }

      return res.json(result);
    });
  },

  delete: function (req, res) {

    var email = req.session.email;

    if (!email) {
      return res.json({
        success: false,
        error: 'You must be logged in.'
      });
    }

    var msgID = req.param('id') || null;

    if (!msgID) {
      return res.json({
        success: false,
        error: 'Notification ID was not provided.'
      });
    }

    if (msgID.indexOf(email) !== 0) {

      return res.json({
        success: false,
        error: 'The message you want to delete does not belongs you.'
      });
    }


    async.waterfall([function(callback) {
      Notification.native(callback);
    },
    function(collection, callback) {
      collection.select(getRedisNotificationDB(), function(err) {
        callback(err, collection);
      });
    },
    function(collection, callback) {
      collection.del(msgID, callback);
    }], function(err, deleted) {

      if (err) {
        return console.log(err);
      }

      return res.json({
        success: true,
        keys_deleted: deleted
      });
    });
  },


  /**
  * Overrides for the settings in `config/controllers.js`
  * (specific to StatusController)
  */
  _config: {}


};
