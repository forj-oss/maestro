
'use strict';

/**
 * Moduel dependencies
 */

var path = require('path');
var util = require('util');

var pkg = require( path.join(__dirname,'..','package.json') );

var nconf = require('nconf').file({
  file : path.join( __dirname, '..', 'config', 'global.json' )
});

/**
 * Tests
 */

var testName = util.format(
  '%s v%s',
  nconf.get('App:Name'),
  pkg.version
);

describe(testName, function() {

  before(function( done ) {
    require('../maestro-api').listen( done );
  });

  require( path.join( __dirname, 'routes', 'ping' ) );

});
