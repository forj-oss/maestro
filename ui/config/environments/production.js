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
    branch: 'stable',

    kit: {
        registration: {
            protocol: "http",
            ip: 'reg.forj.io',
            port: '3135',
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
    },
    backups: {
        path: '/mnt/backups',
        backup_status_yaml: '/mnt/backups/backup-status.yaml',
        backup_status_cmd: '/usr/lib/forj/sbin/backup-status.py',
        conf_dir: '/etc/forj/conf.d',
        runbkp_cmd: '/usr/lib/forj/sbin/runbkp.sh',
        restore_cmd: '/usr/lib/forj/sbin/restoreraid.sh',
        ok: '0',
        warning: '1',
        error: '2'
    },
    plugins: {
      auth: [
        { name: 'keystone', display_name: 'Keystone', path: '../../plugins/auth/keystone/keystone.js', default: false, auth_basic: true },
        { name: 'openid', display_name: 'OpenID', path: '../../plugins/auth/openid/openid.js', default: true, auth_basic: false },
        { name: 'ldap', display_name: 'LDAP', path: '../../plugins/auth/ldap/ldap.js', default: false, auth_basic: true }
     ]
    },
    fog: {
      path: process.env['FOG_RC'] !== undefined ? process.env['FOG_RC'] : '/opt/config/fog/cloud.fog'
    },
    config: {
        location: '/opt/config/production/config.json'
    },
    api: {
      metric: {
        endpoint: 'http://localhost:8087/api/v1.0',
        max_retry: '4'
      }
    }
};
