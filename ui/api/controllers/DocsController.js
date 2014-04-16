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
var blueprint_utils = require('blueprint/blueprint');
module.exports = {
    
  
  /**
   * Action blueprints:
   *    `/docs/disp`
   */
   index : function (req, res) {
    blueprint_utils.get_blueprint_id(function(err){
      console.log('Unable to get the instance_id of the kit: '+err.message);
      res.view('500', { layout: null, errors: [ 'Unable to get the instance_id of the kit: '+err.message ]});
    }, function(result){
      var id = JSON.parse(result).id;
      blueprint_utils.get_blueprint_section(id, 'documentation', function(err){
        //Suppress the error and log the exception
        console.log('Unable to retrieve the documentation:'+err.message);
        callback();
      }, function(res_docs){
        res_docs = JSON.parse(res_docs);
        if(res_docs instanceof Array){
          res.view({ layout: null, documentation: res_docs }, 200);
        }else{
          res.view({ layout: null, documentation: [] }, 200);
        }
      })
    });
  },


/**
   * Overrides for the settings in `config/controllers.js`
   * (specific to DocsController)
   */
  _config: {}

  
};
