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
 * BpController
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
  var config = require('config/config');
  var blueprint_utils = require('blueprint/blueprint');
  var config_module = require('config_module/config_module');
  
module.exports = {
    
  


  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to BpController)
   */
  _config: {},
  filter: function(req, res){
    var id = req.param('id');
    var model = req.param('model');
    var query = req.param('query');
    if(id === undefined && model === undefined && query === undefined){
      blueprint_utils.get_all(function(err){
        res.json('Error getting the list of available blueprints.', 500);
      },function(bps){
        res.json(bps, 200);
      });
    }else{
     
      if(id === undefined || model === undefined){
        res.json('Missing parameters id or model', 500);
      }else{
        
        blueprint_utils.get_blueprint(id, function(err){
          res.json("We couldn't get the blueprint information. Error:"+err.message, 500);
        },function(bp){
          if(bp === undefined){
            res.json('Blueprint not found', 404);
          }else{
            if(bp[model] === undefined){
              res.json("Blueprint found, but the attribute that you requested doesn't exist", 404);
            }else{
              if(query === undefined){
                res.json(bp[model], 200);
              }else{
                query = JSON.parse(query);
                if(query instanceof Error){
                  res.json("Invalid query, must be a valid JSON.", 500);
                }else{
                  blueprint_utils.get_blueprint_part_where(id, model, query, function(errq){
                    res.json(errq, 500);
                  }, function(bpq){
                    if(bpq === undefined){
                      res.json('Blueprint not found with the specified criteria.', 404);
                    }else{
                      res.json(bpq, 200);
                    }
                  });
                }
              }
            }
          }
        });
        
      }
      
    }
  },
  id: function(req, res){
    var config_content = config.get_config_data();
    if(config_content === undefined){
      res.json('We could not read the configuration file.', 500);
    }else{
      blueprint_utils.get_kit_blueprint_sync(function(err){
        res.json(err, 500);
      }, function(bp){
        res.json({ id: bp.id }, 200);
      });
    }

  },
  current_raw_bp: function(req, res){
    var config_content = config.get_config_data();
    if(config_content === undefined){
      res.json('We could not read the configuration file.', 500);
    }else{
      res.json(JSON.parse(config_content), 200);
    }
  }
};
