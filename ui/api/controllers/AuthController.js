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
 
  var crypto = require('crypto');
  var openid = require('openid-request');
  var kit_ops = require('kit-ops/kit-ops');
  var check_grav = require('check-grav/check-grav');
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
    findElement(sails.config.env.plugins.auth, 'default', true, function(auth_plugin){
      res.view({ default_auth: auth_plugin.name, layout: 'login_layout', message: message });
    });
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
  authenticate: function(req, res){
    var module = req.param('module');
    findElement(sails.config.env.plugins.auth, 'name', module, function(auth_plugin){
    //Check if the plugin exist
    if(auth_plugin !== undefined){
      
      var auth_module = require(auth_plugin.path);
      //Check if our plugin has an authentication method
      if(auth_module.authenticate !== undefined){
        
        //We pass the entire req (request) object to our plugin and the plugin will grab everything that he needs like headers, body, params to make the authentication happen
        auth_module.authenticate(req, function(error, redirect, authenticated){
        
          if(error){
          
            //If we got an error we send the error to the user
            res.send(error, 500);
          
          }else{
            if(authenticated === true){
            
              //User gets authenticated
              res.send(200);
            
            }else if(redirect !== null){
            
              //We redirect the user outside of Maestro (OAuth, OpenID style)
              req.session.auth_method = module;
              res.writeHead(302, { Location: redirect });
              res.end();
            
            }else{
            
              //If we land here that means that the authentication is false and we don't need to redirect the user so we send an Unauthorized HTTP Code (401)
              res.send(401);
            
            }
          }
          
        });
       
      }else{
        res.send('Auth module does not have an authentication method', 409);
      }
    }else{
      res.send('Auth module '+module+', does not exist.', 404);
    }
   });
  },
  verify: function(req, res){
    var module = req.session.auth_method;
    findElement(sails.config.env.plugins.auth, 'name', module, function(auth_plugin){
    //Check if the plugin exist
    if(auth_plugin !== undefined){
      
      var auth_module = require(auth_plugin.path);
      //Check if our plugin has an authentication method
      if(auth_module.verify !== undefined){
        
        //We pass the entire req (request) object to our plugin and the plugin will grab everything that he needs like headers, body, params to make the authentication happen
        auth_module.verify(req, function(error, result){
          if(error){
            
            console.log('[Auth Verify] Error trying to verify the user: '+ error);
            console.log('[Auth Verify] Result: '+ JSON.stringify(result));
            
            req.session.project_visibility = result.project_visibility;
            req.session.authenticated = result.authenticated;
            req.session.gravatar_hash = result.gravatar_hash;
            req.session.has_gravatar = result.has_gravatar;
            req.session.is_admin = result.is_admin;
            req.session.email = result.email;
            
            //Clean the auth_method
            req.session.auth_method = null;

            res.redirect('/', 301);
          }else{
            
            req.session.project_visibility = result.project_visibility;
            req.session.authenticated = result.authenticated;
            req.session.gravatar_hash = result.gravatar_hash;
            req.session.has_gravatar = result.has_gravatar;
            req.session.is_admin = result.is_admin;
            req.session.email = result.email;
            
            //Clean the auth_method
            req.session.auth_method = null;
            
            res.redirect('/', 301);
          }
        });
      }else{
        res.send('Auth module does not have an authentication method', 409);
      }
    }else{
      res.send('Auth module '+module+', does not exist.', 404);
    }
   });
  }
};
function findElement(array, propName, propValue, callback){
	var item;
	array.forEach(function(element){
		if(element[propName] === propValue){
			item = element;
		}
	});
	callback(item);
}