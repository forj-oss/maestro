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
 * HomeController
 *
 * @module      :: Controller
 * @description :: A set of functions called `actions`.
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
"use strict";
 var async = require('async');
 var blueprint_utils = require('blueprint/blueprint');
 var kit_ops = require('kit-ops/kit-ops');
 var backup_utils = require('backup/backup');
 var jsonPath = require('JSONPath');

module.exports = {




  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to HomeController)
   */
  _config: {},
  index: function(req, res){
    blueprint_utils.get_blueprint_id(function(err){
        console.error('Unable to get the instance_id of the kit: '+err.message);
        res.view('500', { layout: null, errors: [ 'Unable to get the instance_id of the kit. ' ]});
      }, function(result){
        if(!result){
          res.view('500', { layout: null, errors: [ 'Unable to get the instance_id of the kit. ' ]});
        }else{
          try{
            result = JSON.parse(result);
          }catch(e){
            result = new Error('Unable to parse malformed JSON');
            console.error('Unable to parse malformed JSON: ' + e.message);
          }
          if(result instanceof Error){
            res.view('500', { layout: null, errors: [ 'Unable to get the instance_id of the kit: ' + result.message ]});
            console.error('Unable to get the instance_id of the kit (result instanceoff Error): ' + result.message);
          }else{
            var tools = [];
            async.series({
                jsonPath: function(callback){
                  callback(null, jsonPath); // Telling async that we are done
                },
                backupYaml: function(callback){  // Yaml object from backup-status.yaml
                  backup_utils.getYamlObj(function (error, yamlObj) {
                    if(error){
                      console.error(error);
                      callback(null, {});  // Empty object
                    } else {
                      callback(null, yamlObj); // Telling async that we are done
                    }
                  });
                },
                tools: function(callback){
                  blueprint_utils.get_blueprint_section(result.id, 'tools', function(err){
                    console.error('Unable to retrieve the list of tools:'+err.message);
                    callback(err, tools);
                  }, function(res_tools){
                    tools = JSON.parse(res_tools);
                    callback(null, tools);
                  });
                },
                layout: function(callback){
                  if(req.isAjax){
                    callback(null, null);
                  }else{
                    callback(null, 'layout');
                  }
                }
            }, function(errasync, results) {
                if (errasync) {
                  console.error(errasync.message);
                  res.view('500', { layout: null, errors: [ errasync.message ]});
                }else{
                  res.view(results, 200);
                }
            });
          }
        }
      });
  },
  util_info: function(req, res){
    var service = req.param('service');
    var app = req.param('app');
    async.series({
          jsonPath: function(callback){
            var jsonPath = require('JSONPath');
            callback(null, jsonPath); // Telling async that we are done
          },
          backupInfo: function(callback){  // App yaml with backup information
            backup_utils.getBackupInfo(app, function (error, data) {
              if(error){
                console.error(error);
                callback(null, {});  // Empty object
              } else {
                callback(null, data); // Telling async that we are done
              }
            });
          },
          backupList: function(callback){  // App yaml with backup information
            backup_utils.getBackupList(app, function (error, weeks) {
              if(error){
                console.error(error);
                callback(null, {});  // Empty object
              } else {
                console.log('Backups count: ' + weeks.length);
                for (var i=0; i<weeks.length; i++){
                    console.log('Files: ' + weeks[i]);
                }
                callback(null, weeks); // Telling async that we are done
              }
            });
          },
          layout: function(callback){
              callback(null, null);
          },
          service: function(callback){
              callback(null, service);
          },
          app: function(callback){
              callback(null, app);
          }
      }, function(errasync, results) {
          if (errasync) {
            console.error(errasync.message);
            res.view('500', { layout: null, errors: [ errasync.message ]});
          }else{
            //res.view(results, 200);
            res.view(results);
          }
      });


    //res.view({ layout: null, service: service });
  },
  tutorial: function(req, res){
    blueprint_utils.get_blueprint_id(
      function(err){
          console.error('Unable to get the instance_id of the kit: '+err.message);
          res.view({ layout: null, gerrit_ip: 'my_gerrit_ip', zuul_ip: 'my_zuul_ip' });
        },
      function(result){
        result = JSON.parse(result);
        blueprint_utils.get_blueprint_section(result.id, 'tools',
          function(err){
              console.error('Unable to retrieve the list of tools:'+err.message);
            res.view({ layout: null, gerrit_ip: 'my_gerrit_ip', zuul_ip: 'my_zuul_ip' });
            },
          function(result){
            result = JSON.parse(result);
            var gerrit_ip = 'my_gerrit_ip';
            var zuul_ip = 'my_zuul_ip';
            for (var i=0; i<result.length; i++){
              if (result[i].name == "gerrit"){
                  // Only nums and point
                gerrit_ip = result[i].tool_url.replace(/[^0-9.]/g, '');
                if (!gerrit_ip){
                  gerrit_ip = 'my_gerrit_ip';
                }
              }
              if (result[i].name == "zuul"){
                zuul_ip = result[i].tool_url.replace(/[^0-9.]/g, '');
                if (!zuul_ip){
                  zuul_ip = 'my_zuul_ip';
                }
              }
            }
              res.view({ layout: null, 'gerrit_ip': gerrit_ip, 'zuul_ip': zuul_ip });
            }
          );
      }
    );
  },
  projects: function(req, res){
    res.view({ layout: null });
  },
  user_options: function(req, res){
    if(req.session.authenticated){
      res.view({ layout: null, guest: false });
    }else{
      res.view({ layout: null, guest: true });
    }
  },
  notifications_enabled: function(req, res){

    kit_ops.get_opt('show_welcome_notification', function(open_err, identifier){
      if(open_err){
        res.view('500', { layout: null, errors: [ open_err.message ]});
      }else{
        var notificationID = identifier.option_id;
        // var notificationValue = identifier.option_value;

        if(!notificationID){
          res.view('500', { layout: null, errors: [ 'We could not retrieve the notificationID' ]});
        }else{

          var enabled = req.param('enabled');
          kit_ops.enable_notifications(enabled, notificationID, function(error, success){
            if(error){
               res.json({ result: success  }, 500);
            }else{
              req.session.show_welcome_message = enabled;
              res.json({ result: success  }, 200);
            }
          });
        }
      }
    });
  }
};
