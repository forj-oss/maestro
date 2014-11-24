
'use strict';

var util = require('util');
var path = require('path');
var redis = require('redis');
var restify = require('restify');
var nconf = require('nconf').file({
  file: path.join( __dirname, '../../../config', 'global.json' )
});


/**
 * Routes
 */

var routes = [];
var prefix = nconf.get('API:Prefix');

/**
 * @api {get} /api/v1.0/metric/:host/:metric
 * @apiVersion 1.0.0
 * @apiParam {String} host   Name of the host
 * @apiParam {String} metric Name of the metric
 * @apiDescription Returns a health status of the endpoint.
 * @apiSuccessExample {json} Success-Response:
 *     HTTP/1.1 200 OK
 *     {
 *       "metric": "20"
 *     }
 */

routes.push({
  meta: {
    name: 'getMetricV1.0',
    method: 'GET',
    paths: [
      '/'+prefix+'/v1.0/metric/:host/:metric'
    ],
    version: nconf.get('API:ver1')
  },
  middleware: function( req, res, next ) {

      var key = req.params.host+':'+req.params.metric;
      try {
        var client = redis.createClient(nconf.get('redis:port'), nconf.get('redis:host') , {});
        client.select(nconf.get('redis:db'));
        client.get(key,function(err, result) {
          client.quit();
          if(err) {
            console.log(err);
            return next( new restify.InternalError(err) );
          } else if(!result) {
            var msg = util.format('key:%s was not found', key);
            console.log(msg);
            return next( new restify.ResourceNotFoundError(msg) );
          } else {
            res.send({
              metric: result
            });
            return next();
          }
        });
      } catch(error) {
          return next( new restify.InternalError(error) );
        }
  }
});



/**
 * Export
 */

module.exports = routes;
