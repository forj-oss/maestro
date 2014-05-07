/**
    (c) Copyright 2014 Hewlett-Packard Development Company, L.P.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
/**
 * StatusController
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
   *    `/status/display`
   */
   display: function (req, res) {
    var type = req.param('type');
    var service = req.param('service');
    
    if(type == 'tools'){
      var backups = require('../../node_modules/backup/backup.js').get_backup_data();
      var has_backups = true;
      if(!backups[service]){
        has_backups = false;
      }
      return res.json({
        success: true,
        type: type,
        service: service,
        has_backups: has_backups,
        message: backups[service]
      });
    }else{
      return res.json({
        success: false,
        type: type,
        service: service,
        has_backups: false,
        message: 'unknown type.'
      });
    }
  },
  show: function(req, res){
    res.view();
  },

  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to StatusController)
   */
  _config: {}

  
};
