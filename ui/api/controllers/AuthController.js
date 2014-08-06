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
  var openid = require('openid-request');
  var crypto = require('crypto');
  var check_grav = require('check-grav/check-grav');
  var blueprint_utils = require('blueprint/blueprint');
  var kit_ops = require('kit-ops/kit-ops');
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
  sign_out: function(req, res){
    req.session.destroy();
    res.view({ layout: 'login_layout' });
  },
  login: function(req, res){
    res.view({ layout: 'login_layout' });
  },
  first_admin: function(req, res){
    res.view({ layout: 'login_layout' });
  },
  auth: function(req, res){
    kit_ops.get_opt('openid_url', function(open_err, identifier){
      if(open_err){
        res.view('500', { layout: null, errors: [ 'Unable to authenticate with the provider: '+open_err ]});
      }else{
        var openid_url = identifier.option_value;
        if(openid_url === undefined){
          res.view('500', { layout: null, errors: [ 'We could not retrieve the openid provider' ]});
        }else{
          getRelyingParty(function(err, relyingParty){
            if(err){
              res.view('500', { layout: null, errors: [ err.message ]});
            }else{
              relyingParty.authenticate(openid_url, false, function(error, authUrl)
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
          });
        }
      }
    });
  },
  verify: function(req, res){
    getRelyingParty(function(err, relyingParty){
      if(err){
		console.error('Failed to autenticate:'+err.message);
        res.view('500', { layout: null, errors: [ 'Failed to autenticate:'+err.message ]});
      }else{
        relyingParty.verifyAssertion(req, function(error, result)
        {
          if(error){
            console.error(error.message);
            res.view({ layout: null, errors: [ error.message ]}, '500');
          }else{
            req.session.authenticated = result.authenticated;
            req.session.email = result.email;
            req.session.gravatar_hash = crypto.createHash('md5').update(result.email).digest('hex');
            req.session.claimedIdentifier = result.claimedIdentifier;
            if(req.session.authenticated === true){
              check_grav.gravatar_exist(req.session.gravatar_hash, function(has_grav){
                req.session.has_gravatar = has_grav;
                kit_ops.kit_has_admin(function(err_ka, result_ka){
                  if(err_ka){
                    //Supress the error and send the user to index?
                    console.error('Unable to check if the kit had an admin already: '+err_ka.message);
                    res.redirect('/', 301);
                  }else{
                    if(result_ka){
                      //Yes
                      kit_ops.is_admin(req.session.email, function(err_ia, result_ia){
                        if(err_ia){
                          //Supress the error and send the user to index?
                          console.error('Unable to check is an admin: '+err_ia.message);
                          res.redirect('/', 301);
                        }else{
                          //True or false
                          req.session.is_admin = result_ia;
                          req.session.project_visibility = projectsVisibility(req.session.is_admin, req.session.authenticated, req.session.global_manage_projects);
                          res.redirect('/', 301);
                        }
                      });
                    }else{
                    //No
                      kit_ops.create_kit_admin(req.session.email, function(err_ca, result_ca){
                        if(err_ca){
                          //Supress the error and send the user to index?
                          console.error('Unable to create the kit admin: '+err_ca.message);
                          res.redirect('/', 301);
                        }else{
                          //True or false
                          req.session.is_admin = result_ca;
                          res.redirect('/', 301);
                        }
                      });
                    }
                  }
                });
              });
            }else{
              console.error('Unable to authenticate the user');
              res.redirect('/', 301);
            }
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
function projectsVisibility(is_admin, is_authenticated, global_manage_projects){
  var anonymous = 'anonymous';
  var authenticated = 'authenticated';
  if(is_admin){
    return true;
  }else{
    if(global_manage_projects !== null){
      if(global_manage_projects === anonymous){
        return true
      } else if(global_manage_projects === authenticated && is_authenticated === true){
        return true;
      }else{
        return false;
      }
    }else{
      return false;
    }
  }
}