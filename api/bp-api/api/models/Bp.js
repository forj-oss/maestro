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
 * Bp
 *
 * @module      :: Model
 * @description :: A short summary of how this model works and what it represents.
 * @docs		:: http://sailsjs.org/#!documentation/models
 */

module.exports = {

  attributes: {
    shortname: {
      type: 'text'
    },
    id: {
      type: 'string',
      maxLength: 8,
      minLength: 1,
      required: 'true'
    },
    tools: {
      type: 'json'
    },
    defect_tracker: {
      type: 'json'
    },
    auth: {
      type: 'json'
    },
    users: {
      type: 'json'
    },
    projects: {
      type: 'json'
    },
    documentation: {
      type: 'json'
    },
    maestro_url: {
      type: 'text'
    },
    blueprint_name: {
      type: 'text'
    },
    global_manage_projects: {
      type: 'text'
    }
  }

};
