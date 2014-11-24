
'use strict';

//var util = require('util');
var path = require('path');
var nconf = require('nconf').file({
  file: path.join( __dirname, '../../../config', 'global.json' )
});


/**
 * Routes
 */

var routes = [];
var prefix = nconf.get('API:Prefix');

 /**
 * @api {get} /api/v1.0/ping
 * @apiVersion 1.0.0
 * @apiDescription Returns a health status of the endpoint.
 * @apiSuccessExample {json} Success-Response:
 *     HTTP/1.1 200 OK
 *     {
 *       "ping": "pong"
 *     }
 */

routes.push({
  meta: {
    name: 'getPingV1.0',
    method: 'GET',
    paths: [
      '/'+prefix+'/v1.0/ping'
    ],
    version: nconf.get('API:ver1')
  },
  middleware: function( req, res, next ) {
    res.send({
      ping: 'pong'
    });
    return next();
  }
});



/**
 * Export
 */

module.exports = routes;
