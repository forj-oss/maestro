/**
 * DocsController
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
   * Action blueprints:
   *    `/docs/disp`
   */
   index : function (req, res) {
    var blueprint_utils = require('../../node_modules/blueprint/blueprint.js');
    blueprint_utils.get_kit_blueprint(function(err){
      res.view('500', { layout: null, errors: [ err ] });
    }, function(bp){
      res.view({ layout: null, documentation: bp.documentation }, 200);
    });
  },


/**
   * Overrides for the settings in `config/controllers.js`
   * (specific to DocsController)
   */
  _config: {}

  
};
