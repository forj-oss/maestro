/**
 * Maestro UI  configuration
 *
 * Configure the backend services,features,options,etc..,
 * the settings here will be merged with the global sails.config object
 * after the app is 'lifted' you can access these values like so:
 *    sails.config.env.kit.registration.ip
 *
 * the actual environment is selected depending on the value of NODE_ENV env var
 * current values supported are: 'development', 'test', and 'production'
 *
 * note: if any values here change, the app must be re-lifted
 *       if NODE_ENV is empty then app mode defaults to 'development'
 *
 */

module.exports.env = {
    branch: 'master',

    kit: {
        registration: {
            protocol: "http",
            ip: '15.185.92.168',
            port: '3131',
            resource_uri: '/devkit/'
        },
        blueprint: {
           protocol: 'http',
           ip: '127.0.0.1',
           port: '3180',
           resource_uri: '/bp'
        }
    },
    services : {
        runtime: {
          protocol: 'http',
          ip: '127.0.0.1',
          port: '8080',
          resource_uri: '/kitops/'
        }
    }
};