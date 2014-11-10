
'use strict';

/**
 * Moduel dependencies
 */

var path = require('path');
var util = require('util');
var get = require( path.join(__dirname,'..','utils','client') ).get;

/**
 * Tests
 */

var route = '/api/v1.0/ping';

var testName = util.format(
  'Ping [%s]',
  route
);

describe(testName, function() {

  describe('[GET as `anonymous`]', function() {

    it('[GET as anonymous] - should return status code 200', function( done ) {
      get( route, 'anonymous' )
        .expect( 200 )
        .end(function( err, res ) {
          if ( !!err ) {
            console.error( res.body );
            return done( err );
          }
          return done();
        });
    });

    it('[GET as anonymous] - should respond with json', function( done ) {
      get( route, 'anonymous' )
        .set( 'Accept', 'application/json' )
        .expect( 'Content-Type', /json/ )
        .expect( 200, done );
    });

  });

});
