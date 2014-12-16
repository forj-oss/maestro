/**
*# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
*#
*#   Licensed under the Apache License, Version 2.0 (the "License");
*#   you may not use this file except in compliance with the License.
*#   You may obtain a copy of the License at
*#
*#       http://www.apache.org/licenses/LICENSE-2.0
*#
*#   Unless required by applicable law or agreed to in writing, software
*#   distributed under the License is distributed on an "AS IS" BASIS,
*#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*#   See the License for the specific language governing permissions and
*#   limitations under the License.
*/
'use strict';

var msg = require('../msg-util.js').Message;
var test = require('unit.js');

describe("Message", function() {
  describe("valid message payload", function() {
    it("should match action context", function() {

      var options = {
        ctx: 'project.create.foo',
        name: 'wenlock',
        desc: 'my project',
        id: '19m',
        user: 'wenlock@hp.com',
        role: 'admin',
        debug: true,
        log: {
          enable: true,
          level: 'info',
          target: 'myfoo'
        },
        origin: 'util'
      };
      var payload = msg.getJSON(options);
      console.log(payload);
      test.assert.equal(payload.message.action.context,options.ctx);
    });

    it("missing site_id", function() {

      var options = {
        ctx: 'project.create.foo',
        name: 'wenlock',
        desc: 'my project',
        user: 'wenlock@hp.com',
        role: 'admin',
        debug: true,
        log: {
          enable: true,
          level: 'info',
          target: 'myfoo'
        },
        origin: 'util'
      };
      test.assert.equal(msg.isValid(options),false);
    });
  });
});
