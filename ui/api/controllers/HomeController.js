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
    var blueprint_utils = require('blueprint/blueprint');
    blueprint_utils.get_kit_blueprint(function(err){
      res.view('500', { layout: null, errors: [ err ] });
    }, function(bp){
      res.view({ tools: bp.tools, defect_tracker: bp.defect_tracker }, 200);
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
