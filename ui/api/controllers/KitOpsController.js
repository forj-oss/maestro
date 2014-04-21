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
module.exports = {
    
  


  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to KitOpsController)
   */
  _config: {},
  register: function(req, res){
    console.log(req.session.email);
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
    if(email !== undefined){
      if((name !== undefined && name.length > 0) && validator.isEmail(email) === true){
        name = validator.toString(name);
        register_module.do_register(name, email, function(err){
          console.error("Kit Registration Failed: "+err.message);
          res.json({ success: 'failed', message: 'Kit Registration Failed'}, 500);
        }, function(result){
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
