
/**
 * Maestro UI  configuration
 *
 * Configure the backend services,features,options,etc..,
 * the settings here will be merged with the global sails.config object
 *
 * the actual environment is selected depending on the value of NODE_ENV env var
 * current values supported are: 'development', 'test', and 'production'
 *
 * to run in specific mode do in shell: export NODE_ENV='production'; sails lift
 *
 * note: if any values here change, the app must be re-lifted
 *       if NODE_ENV is empty then app mode defaults to 'development'
 *
 */
var fs = require('fs'),
    _ = require('lodash');

module.exports = (function () {
    var defaults = {
        env: process.env.NODE_ENV || 'development',
        port: process.env.PORT || 1337,
        config: {
            paths: {
                environments: __dirname + '/environments'
            }
        }
    };

    var envConfigPath = defaults.config.paths.environments + '/' + defaults.env + '.js';
    var environment = {};

    if (fs.existsSync(envConfigPath)) {
        var environment = require(envConfigPath);
        console.info('Loaded environment config for ' + defaults.env + '.');
    } else {
        console.warn('Environment config for ' + defaults.env +' not found.');
    }
    return _.merge(defaults, environment);
}());