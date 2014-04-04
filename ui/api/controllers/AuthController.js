/**
 * AuthController
 *
 * @module      :: Controller
 * @description	:: A set of functions called `actions`.
 *
 *                 Actions contain code telling Sails how to respond to a certain type of request.
 *                 (i.e. do stuff, then send some JSON, show an HTML page, or redirect to another URL)
 *
 *                 You can configure the blueprint URLs which trigger these actions (`config/controllers.js`)
 *                 and/or override them with custom routes (`config/routes.js`)
 *
 *                 NOTE: The code you write here supports both HTTP and Socket.io automatically.
 *
 * @docs        :: http://sailsjs.org/#!documentation/controllers
 */
  var openid = require('openid');
  var blueprint_utils = require('blueprint/blueprint');
module.exports = {
    
  


  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to AuthController)
   */
  _config: {},
  index: function(req, res){
    res.view({ layout: 'login_layout' });
  },
  sign_up: function(req, res){
    res.view({ layout: 'login_layout' });
  },
  sign_in: function(req, res){
    var message = req.param('message');
    res.view({ layout: 'login_layout', message: message });
  },
  login: function(req, res){
    res.view({ layout: 'login_layout' });
  },
  first_admin: function(req, res){
    res.view({ layout: 'login_layout' });
  },
  auth: function(req, res){
    var identifier = 'https://www.google.com/accounts/o8/id'
    if(identifier !== undefined){
      getRelyingParty(function(err, relyingParty){
        if(err){
          res.view('500', { error: [ err.message ]});
        }else{
          relyingParty.authenticate(identifier, false, function(error, authUrl)
          {
            if (error)
            {
              res.writeHead(200);
              res.end('Authentication failed: ' + error.message);
            }
            else if (!authUrl)
            {
              res.writeHead(200);
              res.end('Authentication failed');
            }
            else
            {
              res.writeHead(302, { Location: authUrl });
              res.end();
            }
          });
        }
      })
    }else{
      res.view('500', { error: [ 'Error: identifier missing.']});
    }
  },
  verify: function(req, res){
    getRelyingParty(function(err, relyingParty){
      if(err){
        res.view('500', { error: [ 'Failed to autenticate:'+err.message ]});
      }else{
        relyingParty.verifyAssertion(req, function(error, result)
        {
            req.session.authenticated = result.authenticated;
            req.session.email = result.email;
            if(req.session.authenticated === true){
              res.redirect('/', 301);
            }else{
              res.redirect('/auth/sign_in',{ message: 'Unable to authenticate you.' }, 301) ;
            }
        });
      }
    });
  }
  
};
function getRelyingParty(callback){
    var extensions = [new openid.UserInterface(),
                  new openid.SimpleRegistration(
                      {
                        "nickname" : true,
                        "email" : true,
                        "fullname" : true,
                        "dob" : true,
                        "gender" : true,
                        "postcode" : true,
                        "country" : true,
                        "language" : true,
                        "timezone" : true
                      }),
                  new openid.AttributeExchange(
                      {
                        "http://axschema.org/contact/email": "required",
                        "http://axschema.org/namePerson/friendly": "required",
                        "http://axschema.org/namePerson": "required"
                      }),
                  new openid.PAPE(
                      {
                        "max_auth_age": 24 * 60 * 60, // one day
                        "preferred_auth_policies" : "none" //no auth method preferred.
                      })];
    blueprint_utils.get_blueprint_id(function(err){
      callback('Unable to get the instance id'+err.message, null);
    }, function(result){
      var id;
      try{
        id = JSON.parse(result).id;
      }catch(e){
        id = new Error(e.message);
      }
      if(id instanceof Error){
        console.log('Failed to parse the get_blueprint_id result into the instance id');
        callback(id.message, null);
      }else{
        blueprint_utils.get_blueprint_section(id, 'maestro_url', function(err_url){
          //Suppress the error and log the exception
          console.log('Unable to retrieve maestro_url:'+err_url.message);
          callback('Unable to retrieve maestro_url:'+err_url.message, null);
        }, function(maestro_url){
          
          try{
            maestro_url = JSON.parse(maestro_url);
          }catch(e){
            maestro_url = new Error(e.message);
          }
          
          if(maestro_url instanceof Error){
            console.log('Failed to parse the get_blueprint_section result into the maestro_url');
            callback(maestro_url.message, null);
          }else{
            var relyingParty = new openid.RelyingParty(
              maestro_url+'/auth/verify', // Verification URL (yours)
              null, // Realm (optional, specifies realm for OpenID authentication)
              false, // Use stateless verification
              false, // Strict mode
              extensions); // List of extensions to enable and include
            callback(null, relyingParty);
          }
        })
      }
    });
}