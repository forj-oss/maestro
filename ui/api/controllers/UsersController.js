/**
 * UsersController
 *
 * @description :: Server-side logic for managing users
 * @help        :: See http://links.sailsjs.org/docs/controllers
 */
var validator = require('validator');
var users_ldap = require('maestro-users/maestro-users');
module.exports = {
	index: function(req, res){
	  res.view({ layout: null });
	},
	move_user: function(req, res){
	  if(req.session.is_admin){
      var to = req.body.to;
      var from = req.body.from;
      var mail = req.body.mail;
      
      if(validator.isEmail(mail) && validator.isAlpha(to) && validator.isAlpha(from)){
        users_ldap.change_group(mail, to, from, function(err, result){
          if(err){
            res.send(err, 304);
          }else{
            res.send(result, 200);
          }
        })
      }else{
        res.send('Invalid data', 409);
      }
	  }else{
	    res.send(403);
	  }
	},
	sign_up_user: function(req, res){
	  var mail = req.body.mail;
	  var password = req.body.password;
	  var full_name = req.body.full_name;
	  
	  if(validator.isEmail(mail) && validator.isAlphanumeric(password)){
	    users_ldap.add_guest_user({ full_name: full_name, mail: mail, password: password }, function(err, result){
	      if(err){
	        
	        console.log('sign up user error: '+JSON.stringify(err));
	        
	        if(err.code === 68){
	          res.send(304);
	        }else{
	          res.send(500);
	        }
	        
	      }else{
	        res.send(result, 200);
	      }
	    });
	  }else{
	    res.send('Invalid data', 409);
	  }
	},
	get_users: function(req, res){
	  if(req.session.is_admin){
      var group = req.param('group');
  	  if(group === 'developers'){
  	    users_ldap.get_developers(function(err, users){
    	    if(err){
    	      res.send(err, 500);
    	    }else{
    	      res.send(users, 200);
    	    }
  	    });
  	  }else if(group === 'admins'){
  	    users_ldap.get_admins(function(err, users){
    	    if(err){
    	      res.send(err, 500);
    	    }else{
    	      res.send(users, 200);
    	    }
  	    });
  	  }else if(group === 'operators'){
  	    users_ldap.get_operators(function(err, users){
    	    if(err){
    	      res.send(err, 500);
    	    }else{
    	      res.send(users, 200);
    	    }
  	    });
  	  }else if(group === 'guest'){
  	    users_ldap.get_guest(function(err, users){
    	    if(err){
    	      res.send(err, 500);
    	    }else{
    	      res.send(users, 200);
    	    }
  	    });
  	  }else{
  	    res.send(400);
  	  }
	  }else{
	    res.send(403);
	  }
	}
};