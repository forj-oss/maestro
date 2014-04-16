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
        res.view('500', { errors: [ 'Unable to get the instance_id of the kit: '+err.message ]});
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
          var defect_tracker = [];
          var projects = false;
          var users = false;
          
          async.series({
              tools: function(callback){
                blueprint_utils.get_blueprint_section(result.id, 'tools', function(err){
                  //Suppress the error and log the exception
                  console.error('Unable to retrieve the list of tools:'+err.message);
                  callback(err.message, null);
                }, function(res_tools){
                  tools = JSON.parse(res_tools);
                  if(tools instanceof Array){
                    callback(null, tools);
                  }else{
                    callback(null, []);
                  }
                })
              },
              defect_tracker: function(callback){
                blueprint_utils.get_blueprint_section(result.id, 'defect_tracker', function(err){
                  //Suppress the error and log the exception
                  console.error('Unable to retrieve the list of defect_trackers:'+err.message);
                  callback(err.message, null);
                }, function(res_dt){
                  defect_tracker = JSON.parse(res_dt);
                  if(defect_tracker instanceof Array){
                    callback(null, defect_tracker);
                  }else{
                    callback(null, []);
                  }
                })
              },
              projects: function(callback){
                blueprint_utils.get_blueprint_section(result.id, 'projects', function(err){
                  //Suppress the error and log the exception
                  console.error('Unable to retrieve the value of projects:'+err.message);
                  callback(err.message, null);
                }, function(res_pj){
                  projects = JSON.parse(res_pj);
                  if(projects instanceof Array){
                    callback(null, projects);
                  }else{
                    callback(null, []);
                  }
                })
              },
              users: function(callback){
                blueprint_utils.get_blueprint_section(result.id, 'users', function(err){
                  //Suppress the error and log the exception
                  console.error('Unable to retrieve the value of users:'+err.message);
                  callback(err.message, null);
                }, function(res_us){
                  users = JSON.parse(res_us);
                  if(users instanceof Array){
                    callback(null, users);
                  }else{
                    callback(null, []);
                  }
                })
              },
              auth: function(callback){callback(null, null);},
              admin: function(callback){
                callback(null, req.session.is_admin);
                //callback(null, true);
              },
              layout: function(callback){
                if(req.isAjax){
                  callback(null, null);
                }else{
                  callback(null, 'layout')
                }
              },
              email: function(callback){
                callback(null, req.session.email);
              }
          }, function(errasync, results) {
              if (errasync) {
                console.error('Error getting the tools and defect tracker: '+errasync.message)
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
    //TODO: integrate nagios
    var service = req.param('service');
    var backups = require('backup/backup').get_backup_data();
    var has_backups = true;
    if(!backups[service]){
        has_backups = false;
    }
    res.view({ layout: null, backup_service: service, has_backups: has_backups });
  },
  tutorial: function(req, res){
    res.view({ layout: null });
  },
  projects: function(req, res){
    res.view({ layout: null });
  }
};
