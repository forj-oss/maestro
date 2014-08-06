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
 * KitOpsController
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
var validator = require('validator');
var register_module = require('kit-reg/kit-reg');
var maestro_exec = require('maestro-exec/maestro-exec');
 
module.exports = {
    
  


  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to KitOpsController)
   */
  _config: {},
  register: function(req, res){
    if(req.session.email === undefined){
      res.redirect('/auth/sign_in', 301);
    }else{
      register_module.is_registered(function(err){
        console.error(err.message);
        res.view({ layout: null, registered: 0, error_message: err.message });
      }, function(result){
        res.view({ layout: null, registered: result.result, error_message: null });
      })
    }
  },
  do_register: function(req, res){
    var name = req.param('name');
    var email = req.session.email;
    var claimedIdentifier = req.session.claimedIdentifier;
    if(email !== undefined){
      if((name !== undefined && name.length > 0) && validator.isEmail(email) === true){
        name = validator.toString(name);
        register_module.do_register(name, email, function(err){
          console.error("Kit Registration Failed: "+err.message);
          res.json({ success: 'failed', message: 'Kit Registration Failed'}, 500);
        }, function(result){
          if (req.session.blueprint_name.toUpperCase() == 'REDSTONE'){ 
            var minionCmd = "/usr/bin/python /opt/config/production/lib/create_admin.py --username '" + name +  "' --email '" + email + "' --claimed_id '" + claimedIdentifier +  "'";
            var saltCmd = "sudo -u salt /usr/bin/salt 'review.*' --out=json cmd.retcode \"" + minionCmd +"\"";
            maestro_exec.execCmd(saltCmd, function (error, stdout, stderr) {
              if(error){
                console.error('Gerrit Admin account creation failed: ' + stderr);
                res.json({ success: 'failed', message: 'Gerrit Admin account creation failed.' }, 409);
              }
            });
          }
          console.info("Kit Registration: "+result.state+", Stacktrace: "+result.stacktrace);
          res.json({ success: result.state, message: result.stacktrace }, 200);
        })
      }else{
        res.json({ success: 'failed', message: 'Invalid name or email address.' }, 409);
      }
    }else{
      res.redirect('/auth/sign_in', 301);
    }
  }
};
