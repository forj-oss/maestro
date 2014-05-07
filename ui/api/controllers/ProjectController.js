/**
 * ProjectController
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

/**
 *
 * @type {{create: create, _config: {}}}
 */
 var maestro_exec = require('maestro-exec/maestro-exec');
module.exports = {
  /**
   * Action blueprints:
   *    `/project/create`
   */
  create: function (req, res) {
    maestro_exec.execCmd('sudo ./config/newproject.sh', req.body.project_name, { status_only: true }, function(data){
     res.json(data);
    });
  },
  index: function(req, res){
    res.view({ layout: null });
  },
  new: function(req, res){
    res.view({ layout: null });
  },
  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to ProjectController)
   */
  _config: {}

  
};
