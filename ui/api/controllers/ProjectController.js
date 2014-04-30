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
module.exports = {
    
  
  /**
   * Action blueprints:
   *    `/project/create`
   */
   create: function (req, res) {

   // hack!! salt.controllers.<controller-name>.function()
   // calls another controller's action....
   // example below: works, not sure this cool...
   // sails.controllers.command.exec(req, res);

   // using a service from api/service
   /** example:
   CommandSvc.CommandExec('/bin/ls', '/home/miqui',{status_only: true}, function(data) {
          return res.json({exec: data})
   })
   */

  },





  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to ProjectController)
   */
  _config: {}

  
};
