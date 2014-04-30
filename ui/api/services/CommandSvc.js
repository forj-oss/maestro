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