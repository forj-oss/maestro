var fs   = require('fs');
var yaml = require('js-yaml');
var url_parser = require('url');
var request = require('request');
var async = require('async');
var crypto = require('crypto');
var kit_ops = require('../../../node_modules/kit-ops/kit-ops');
var check_grav = require('../../../node_modules/check-grav/check-grav');

module.exports = {
 authenticate: function(req, callback){
    var fog = fog_config();
    if(fog !== null){
         
      // FOR KEYSTONE WE NEED THE USERNAME AND PASSWORD
      var user = req.body.username;
      var password = req.body.password;
      
      var url = fog.auth_url + 'tokens' // GET KEYSTONE IDENTITY URL
      var payload = { auth: { passwordCredentials: { username: user, password: password } } };
      var headers = { 'content-type': 'application/json', 'accept': 'application/json' };
      
      var result = { authenticated: false, email: null, gravatar_hash: null, has_gravatar: false, kit_has_admin: null, is_admin: false, project_visibility: null };
      
      post_request(url, payload, headers, function(error, body, code){
        if(error){
          if(code == 401){
            callback('Unauthorized: '+error, null, null);
          }else{
            callback(error, null, null);
          }
        }else{
          if(code == 200){
            async.series({
              authenticated: function(callback_){
                result.authenticated = true;
                callback_(null, result.authenticated);
              },
              email: function(callback_){
                get_user_mail(body.access.user.id, function(error_, email){
                  if(error_){
                    callback_(error_, null);
                  }else{
                    result.email = email;
                    callback_(null, result.email);
                  }
                });
              },
              gravatar_hash: function(callback_){
                callback_(null, crypto.createHash('md5').update(result.email).digest('hex'));
              },
              has_gravatar: function(callback_){
                check_grav.gravatar_exist(crypto.createHash('md5').update(result.email).digest('hex'), function(has_grav){
                  callback_(null, has_grav);
                });
              },
              kit_has_admin: function(callback_){
                kit_ops.kit_has_admin(function(err_ka, result_ka){
                  if(err_ka){
                    console.log('Unable to check if the kit has an admin');
                    callback_(null, null);
                  }else{
                    result.kit_has_admin = result_ka;
                    callback_(null, result_ka);
                  }
                });
              },
              is_admin: function(callback_){
                kit_ops.is_admin(result.email, function(err_ia, result_ia){
                  if(err_ia){
                    console.log('Unable to check is an admin: '+err_ia.message);
                    callback_(null, false);
                  }else{
                    result.is_admin = result_ia;
                    callback_(null, result_ia);
                  }
                });
              },
              project_visibility: function(callback_){
                callback_(null, null);
              }
            }, function(async_err, async_result) {
              if (async_err) {
                console.error(async_err.message)
              }else{
                if(async_result.kit_has_admin === false){
                  kit_ops.create_kit_admin(async_result.email, function(err_ca, result_ca){
                    if(err_ca){
                      async_result.project_visibility = projectsVisibility(async_result.is_admin, async_result.authenticated, req.session.global_manage_projects);
                      callback(null, null, async_result);
                    }else{
                      if(result_ca){
                        async_result.is_admin = true;
                      }
                      async_result.project_visibility = projectsVisibility(async_result.is_admin, async_result.authenticated, req.session.global_manage_projects);
                      callback(null, null, async_result);
                    }
                  });
                }else{
                  async_result.project_visibility = projectsVisibility(async_result.is_admin, async_result.authenticated, req.session.global_manage_projects);
                  callback(null, null, async_result);
                }
              }
            });
          }else{
            console.log('Unable to authenticate the user ('+user+'), code '+code);
            callback(null, null, result);
          }
        }
      });
      
    }else{
      callback('Unable to retrieve the service account information for keystone', null, null);
    }
 }
}

function fog_config(){
  try{
    var doc = yaml.safeLoad(fs.readFileSync(sails.config.env.fog.path, 'utf8'));
    return doc.keystone_maestro;
  }catch(e){
    return null;
  }
}
function get_user_mail(user_name, callback){
  var fog = fog_config();
  if(fog !== null){
    scoped_token_admin(function(error_admin, admin_token){
      if(error_admin){
        callback(error_admin, null);
      }else{
        var url = fog.admin_url + 'users/' + user_name; // GET KEYSTONE IDENTITY URL
        var headers = { 'accept': 'application/json', 'X-Auth-Token': admin_token };
        get_request(url, headers, null, function(error, body, code){
          if(error){
            callback(error, null);
          }else{
            
            if(body !== undefined){
              body = JSON.parse(body); // PARSE THE RESPONSE BODY
            }
            
            if(code == 200){
              callback(null, body.user.email); // RETURN THE EMAIL ADDRESS
            }else{
              callback('Unable to retrieve the email address of the user ('+user_name+')', null);
            }
            
          }
        });
      }
    });
  }else{
    callback('Unable to retrieve the service account information for keystone', null);
  }
}
function scoped_token_admin(callback){
  var fog = fog_config();
  if(fog !== null){
    var url = fog.auth_url + 'tokens'
    var headers = { 'content-type': 'application/json', 'accept': 'application/json' };
    var payload_admin = { auth: { tenantName: fog.tenant_name, passwordCredentials: { username: fog.username, password: fog.password } } }; // GET THE API KEY FOR THE ADMIN
    post_request(url, payload_admin, headers, function(error, body, code){
      if(code == 200){
        callback(null, body.access.token.id);
      }else{
        callback('Unable to get the token to retrieve the email address', null);
      }
    });
  }else{
    
  }
}
function get_proxy(protocol){
  if(protocol !== 'https:'){
    return (process.env.http_proxy !== null) ? process.env.http_proxy : process.env.HTTP_PROXY;
  }else{
    return (process.env.https_proxy !== null) ? process.env.https_proxy : process.env.HTTPS_PROXY;
  }
}
function get_request(url, headers, timeout, callback){
  var protocol = url_parser.parse(url).protocol;
  var proxy = get_proxy(protocol);
  if(proxy !== undefined){
    request({'url': url , 'proxy': proxy, 'headers': headers, 'timeout': timeout }, function (error, response, body) {
      if (!error && response.statusCode == 200) {
  	    callback(null, body, response.statusCode);
  	  } else {
  	    sails.log.error('Error in get request using proxy settings: '+error);
  	    callback(error, body, response.statusCode);
  	  }
  	});
  }else{
  	request({ 'url': url, 'headers': headers, 'timeout': timeout }, function(error, response, body) {
  		if (!error && response.statusCode == 200) {
  			callback(null, body, response.statusCode);
  		} else {
  		  sails.log.error('Error in get request: '+error);
  			callback(error, body, response.statusCode);
  		}
  	});
  }
}
function post_request(url, payload, headers, callback){
  var protocol = url_parser.parse(url).protocol;
  var proxy = get_proxy(protocol);
  if(proxy !== undefined){
    request.post({ 'url': url, 'proxy': proxy, 'json': payload, 'headers': headers, }, function(error, response, body){
      if (!error && response.statusCode == 200) {
  	    callback(null, body, response.statusCode);
  	  } else {
  	    if(body !== undefined){
  	      callback(body.error.message, null, response.statusCode);
  	    }else{
  	      callback(error, body, response.statusCode);
  	    }
  	  }
    });
  }else{
    request.post({ 'url': url, 'json': payload, 'headers': headers }, function(error, response, body){
      if (!error && response.statusCode == 200) {
  	    callback(null, body, response.statusCode);
  	  } else {
  	    sails.log.error('Error in post request using proxy settings: '+error);
  	    if(response !== undefined){
  	      callback(error, body, response.statusCode);
  	    }else{
  	      callback(error, body, null);
  	    }
  	  }
    });
  }
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