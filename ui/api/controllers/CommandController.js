/**
 * CommandController
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

var maestroexec = require('maestro-exec');

module.exports = {
    
  /**
   * Action blueprints:
   *    `/command/exec`
   */
   /* if you want to capture command output in data
    maestro.execCmd('/bin/ls',' -la /home/miqui/tmp', null, function(data, error) {
        if(error) {
          console.log('my error:' + error);
    } else {
         console.log('my data:' + data);
    }
    });

    or
    like this: to only capture/test data:true/false
    maestro.execCmd('/bin/ls',' -la /home/miqui/tmp', {status_only: true}, function(data) {
       console.log('my data:' + data);
    })
   */
   exec: function (req, res) {

    // Send a JSON response
    return res.json({
      hello: 'world'
    });
  },

  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to CommandController)
   */
  _config: {}
};
