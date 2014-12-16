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
 Message JSON schema
 see: https://github.com/hapijs/joi
*/
'use strict';

var Joi = require('joi');

var schema = {
  message: {
    action: {
      context : Joi.string().required(),
      ctx_data: {
        name: Joi.string().alphanum(),
        description: Joi.string()
      }
    },
    ACL: {
      user: Joi.string().email(),
      role: Joi.string()
    },
    debug: Joi.boolean(),
    log: {
      enable: Joi.boolean(),
      level: Joi.string().valid('info','debug', 'warning', 'critical'),
      target: Joi.string().allow('')
    },
    origin: Joi.string(),
    site_id: Joi.string().alphanum().required()
  }
};

module.exports.schema = schema;
