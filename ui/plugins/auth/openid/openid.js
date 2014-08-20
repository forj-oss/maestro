var async = require('async');
var crypto = require('crypto');
var openid = require('openid-request');
var kit_ops = require('../../../node_modules/kit-ops/kit-ops');
var check_grav = require('../../../node_modules/check-grav/check-grav');
var blueprint_utils = require('../../../node_modules/blueprint/blueprint');
module.exports = {
 authenticate: function(req, callback){
    kit_ops.get_opt('openid_url', function(open_err, identifier){
      if(open_err){
        callback('Unable to authenticate with the provider: '+open_err, null , null);
      }else{
        var openid_url = identifier.option_value;
        if(openid_url === undefined){
          callback('We could not retrieve the openid provider', null , null);
        }else{
          getRelyingParty(function(err, relyingParty){
            if(err){
              callback(err.message, null , null);
            }else{
              relyingParty.authenticate(openid_url, false, function(error, authUrl)
              {
                if (error)
                {
                  callback('Authentication failed: ' + error.message, null , null);
                }
                else if (!authUrl)
                {
                  callback(null, null , false);
                }
                else
                {
                  callback(null, authUrl, null);
                }
              });
            }
          });
        }
      }
    });
 },
 verify: function(req, callback_verify){
  getRelyingParty(function(err, relyingParty){
    if(err){
      callback_verify('Failed to autenticate:'+err.message, null , null);
    }else{
      
      relyingParty.verifyAssertion(req, function(error, result)
      {
        if(error){
          callback_verify(error.message, null , null);
        }else{
          
          
          async.series({
            authenticated: function(callback){
              callback(null, result.authenticated);
            },
            email: function(callback){
              callback(null, result.email);
            },
            claimedIdentifier: function(callback){
              callback(null, result.claimedIdentifier);
            },
            gravatar_hash: function(callback){
              callback(null, crypto.createHash('md5').update(result.email).digest('hex'));
            },
            has_gravatar: function(callback){
              check_grav.gravatar_exist(crypto.createHash('md5').update(result.email).digest('hex'), function(has_grav){
                callback(null, has_grav);
              });
            },
            kit_has_admin: function(callback){
              kit_ops.kit_has_admin(function(err_ka, result_ka){
                if(err_ka){
                  console.log('Unable to check if the kit has an admin');
                  callback(null, null);
                }else{
                  callback(null, result_ka);
                }
              });
            },
            is_admin: function(callback){
              kit_ops.is_admin(result.email, function(err_ia, result_ia){
                if(err_ia){
                  console.log('Unable to check is an admin: '+err_ia.message);
                  callback(null, false);
                }else{
                  callback(null, result_ia);
                }
              });
            },
            project_visibility: function(callback){
              callback(null, null);
            }
          }, function(async_err, async_result) {
            if (async_err) {
              console.error(async_err.message)
            }else{
              if(async_result.kit_has_admin === false){
                kit_ops.create_kit_admin(async_result.email, function(err_ca, result_ca){
                  if(err_ca){
                    async_result.project_visibility = projectsVisibility(async_result.is_admin, async_result.authenticated, req.session.global_manage_projects);
                    callback_verify(null, async_result);
                  }else{
                    if(result_ca){
                      async_result.is_admin = true;
                    }
                    async_result.project_visibility = projectsVisibility(async_result.is_admin, async_result.authenticated, req.session.global_manage_projects);
                    callback_verify(null, async_result);
                  }
                });
              }else{
                async_result.project_visibility = projectsVisibility(async_result.is_admin, async_result.authenticated, req.session.global_manage_projects);
                callback_verify(null, async_result);
              }
            }
          });
          
          
        }
      });
    }
  });
 }
}

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