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

module.exports = {
    
  


  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to HomeController)
   */
  _config: {},
  index: function(req, res){
    var bpm = require('../../node_modules/blueprint/blueprint.js');
    var bp = undefined;
    bpm.get_blueprint('en', function(error){
      
    }, function(bp_){
      bp = bp_
      res.view({ tools: bp_.tools, defect_tracker: bp_.defect_tracker }, 200);
    });
    if(bp instanceof Error){
      console.log('Error trying to get the Blueprint');
      res.view(bp, 500);
    }else{
      if(bp === undefined){
        var data =  require('../../node_modules/config/config.js').get_config_data();
        if(data instanceof Error){
          res.view('Error reading the configuration file.', 500);
        }else{
          console.log('create');
          bpm.create_blueprint('en', data.tools, data.defect_tracker, data.auth, data.projects, data.documentation, function(errc){
            console.log('Error creating the blueprint record from the json file: '+errc);
            res.view(errc, 500);
          }, function(resultc){
            res.view({ tools: resultc.tools, defect_tracker: resultc.defect_tracker }, 200);
          });
        }
      }
    }
  },
  statics: function(req, res){
    //TODO: integrate nagios
    var service = req.param('service');
    var backups = require('../../node_modules/backup/backup.js').get_backup_data();
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
