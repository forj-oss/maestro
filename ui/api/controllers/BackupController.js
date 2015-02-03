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
"use strict";
var backup_utils = require('backup/backup');

module.exports = {
 backup: function(req, res){
    var app = req.param('app');
    console.log ("Running backup for " + app);
    async.series({
      runBackup: function(callback){  // App yaml with backup information
        backup_utils.runBackup(app, function (error, stdout, stderr){
          if(error){
            console.error(error);
            console.error(stderr);
            console.log(stdout);
            callback(error, stdout, stderr);
          } else {
            console.log(app + ' Backup completed succesfully!');
            callback(null, stdout, stderr); // Telling async that we are done
          }
        });
      },
      runBackupStatus: function(callback){  // App yaml with backup information
        backup_utils.runBackupStatus(function (error, stdout, stderr){
          if(error){
            console.error(error);
            console.error(stderr);
            console.log(stdout);
            callback(error, stdout, stderr);
          } else {
            console.log('Generated ' + sails.config.env.backups.backup_status_yaml + ' succesfully!');
            callback(null, stdout, stderr); // Telling async that we are done
          }
        });
      },
      backupInfo: function(callback){  // App yaml with backup information
        backup_utils.getBackupInfo(app, function (error, data) {
          if(error){
            console.error(error);
            callback(error, {});  // Empty object
          } else {
            callback(null, data); // Telling async that we are done
          }
        });
      },
    }, function(errasync, results) {
      if (errasync) {
        console.error(errasync);
        res.json({ status: sails.config.env.backups.error, message: errasync.toString() }, 409);
      }else{
        res.json({ status: results.backupInfo.status, message: results.backupInfo.message }, 200);
      }
    });
  },


  fullBackup: function(req, res){
    console.log ("Running Full Backup");
    backup_utils .runFullBackup(function (error, successMsg){
      if(error){
        console.error(error);
        res.json({ success: 'failed', message: error }, 409);
      } else {
        console.log('Full Backup completed succesfully!');
        res.json({ success: 'success', message: successMsg }, 200);
      }
    });
  },
  restore: function(req, res){
    var app = req.param('app');
    console.log ("Running Restore for " + app);
    var week = req.param('week');
    console.log ("Week: " + week);
    backup_utils.restore(app, week, function (error, stdout, stderr){
      if(error){
        console.error(error);
        res.json({ success: 'failed', message: error + '\n' + stderr }, 409);
      } else {
        console.log(app + ' Restore completed succesfully!');
        res.json({ success: 'success', message: stdout }, 200);
      }
    });
  },
  logs: function(req, res){
    var app = req.param('app');
    console.log ("Downloading " + app + " logs");
    var week = req.param('week');
    console.log ("Week: " + week);
    backup_utils.getLogs(app, week, function (error, logs){
      if(error){
        console.error(error);
        res.view({layout:null, success: 'failed','logs':error.toString(),'week':week,'app':app});
      } else {
        res.view({layout:null, success: 'success', 'logs':logs,'week':week,'app':app});
      }
    });
  }
};
