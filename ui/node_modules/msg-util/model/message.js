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
'use strict';

var Joi = require('joi');
var helpers = require('../lib/helpers');
var schema = require('./schema').schema;

var safeStringify = helpers.safeStringify;

module.exports = function(options) {
    var self  = this;
    self._msg =
    {
      message: {
        action: {
          context : options.ctx,
          ctx_data: {
            name : options.name,
            description: options.desc
          }
        },
        ACL: {
          user: options.user,
          role: options.role
        },
        debug: options.debug,
        log: {
          enable: options.log.enable,
          level: options.log.level,
          target: options.log.target
        },
        origin: options.origin,
        site_id: options.id
      }
    };
    self.getMsg  = function() { return safeStringify(self._msg); };
    self.isValid = function() { return (Joi.validate(self.getMsg(),schema).error === null) ? true:false; };
    self.getJSON = function() { return self._msg; };
};
