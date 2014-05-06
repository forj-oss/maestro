/**
 * HomeController
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
 var async = require('async');
 var blueprint_utils = require('blueprint/blueprint');
module.exports = {
    
  


  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to HomeController)
   */
  _config: {},
  index: function(req, res){
    blueprint_utils.get_blueprint_id(function(err){
        console.log('Unable to get the instance_id of the kit: '+err.message);
        res.view('500', { layout: null, errors: [ 'Unable to get the instance_id of the kit: '+err.message ]});
      }, function(result){
        if(result === undefined){
          res.view('500', { layout: null, errors: [ 'Unable to get the instance_id of the kit: '+err.message ]});
        }else{
          
          try{
            result = JSON.parse(result);
          }catch(e){
            result = new Error('Unable to parse malformed JSON');
          }
          
          if(result instanceof Error){
            res.view('500', { layout: null, errors: [ 'Unable to get the instance_id of the kit: '+result.message ]});
          }else{
            var tools = [];
            async.series({
                tools: function(callback){
                  blueprint_utils.get_blueprint_section(result.id, 'tools', function(err){
                    console.error('Unable to retrieve the list of tools:'+err.message);
                    callback(err, tools);
                  }, function(res_tools){
                    tools = JSON.parse(res_tools);
                    callback(null, tools);
                  })
                },
                layout: function(callback){
                  if(req.isAjax){
                    callback(null, null);
                  }else{
                    callback(null, 'layout')
                  }
                }
            }, function(errasync, results) {
                if (errasync) {
                  console.error(errasync.message)
                  res.view('500', { layout: null, errors: [ errasync.message ]});
                }else{
                  res.view(results, 200);
                }
            });
            
          }
          
        }
      });
  },
  statics: function(req, res){
    var service = req.param('service');
    res.view({ layout: null, service: service });
  },
  tutorial: function(req, res){
	blueprint_utils.get_blueprint_id(
	  function(err){
        console.log('Unable to get the instance_id of the kit: '+err.message);
        res.view({ layout: null, gerrit_ip: 'my_gerrit_ip', zuul_ip: 'my_zuul_ip' });
      },
	  function(result){
	    result = JSON.parse(result);
		blueprint_utils.get_blueprint_section(result.id, 'tools',
		  function(err){
            console.log('Unable to retrieve the list of tools:'+err.message);
			res.view({ layout: null, gerrit_ip: 'my_gerrit_ip', zuul_ip: 'my_zuul_ip' });
          },
		  function(result){
			result = JSON.parse(result);
			var gerrit_ip = 'my_gerrit_ip'
			var zuul_ip = 'my_zuul_ip';
			for (i=0; i<result.length; i++){
			  if (result[i].name == "gerrit"){
                // Only nums and point
				gerrit_ip = result[i].tool_url.replace(/[^0-9.]/g, '');
				if (gerrit_ip == ''){
				  gerrit_ip = 'my_gerrit_ip'
				}
			  }
			  if (result[i].name == "zuul"){
				zuul_ip = result[i].tool_url.replace(/[^0-9.]/g, '');
				if (zuul_ip == ''){
				  zuul_ip = 'my_zuul_ip'
				}
			  }
			}
            res.view({ layout: null, 'gerrit_ip': gerrit_ip, 'zuul_ip': zuul_ip });
          }
        );
	  }
	);
  },
  projects: function(req, res){
    res.view({ layout: null });
  },
  user_options: function(req, res){
    if(req.session.authenticated){
      res.view({ layout: null, guest: false })
    }else{
      res.view({ layout: null, guest: true })
    }
  }
};
