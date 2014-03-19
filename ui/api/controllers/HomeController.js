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
      res.send(500, bp);
    }else{
      if(bp === undefined){
        var data =  require('../../node_modules/config/config.js').get_config_data();
        if(data instanceof Error){
          res.send(500, 'Error reading the configuration file.');
        }else{
          console.log('create');
          bpm.create_blueprint('en', data.tools, data.defect_tracker, data.auth, data.projects, function(errc){
            console.log('Error creating the blueprint record from the json file: '+errc);
            res.send(500, errc);
          }, function(resultc){
            res.view({ tools: resultc.tools, defect_tracker: resultc.defect_tracker }, 200);
          });
        }
      }
    }
  },
  statics: function(req, res){
    //TODO: integrate nagios
    var data = { cpu: 90, memory: 75, disk: 75, users: 32, commits_24: 11, gates: 4  };
    res.view({ layout: null }, data);
  },
  tutorial: function(req, res){
    res.view({ layout: null }, 200);
  },
  projects: function(req, res){
    res.view();
  }
};
