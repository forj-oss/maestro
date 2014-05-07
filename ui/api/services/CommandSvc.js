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
 * Created by miqui on 4/30/14.
 */

var maestro = require('maestro-exec/maestro-exec');

/**
 * CommandExec function to execute a local(on maestro host)
 * @param cmd
 * @param params
 * @param options
 * @param cb
 * @constructor
 */
exports.CommandExec = function(cmd, params, options, cb) {
    maestro.execCmd(cmd, params, options, function(data, error) {
        if(error) {
            cb(error);
        } else {
            cb(data);
        }
    });

};