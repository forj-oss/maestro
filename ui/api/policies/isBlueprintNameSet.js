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
var blueprint_utils = require('blueprint/blueprint');
module.exports = function(req, res, next) {

  // User is allowed, proceed to the next policy,
  // or if this is the last policy, the controller
  if (req.session.blueprint_name) {
    return next();
  }else{
    blueprint_utils.get_blueprint_id(function(error){
      console.error('Unable to get the instance_id of the kit (policies): '+error.message);
      return next();
    }, function(result){
      try{
        result = JSON.parse(result);
        blueprint_utils.get_blueprint_section(result.id, 'shortname', function(err){
          console.error('Unable to get the blueprint name (policies)(get blueprint section): '+err.message);
          return next();
        }, function(bp_name){
          bp_name = JSON.parse(bp_name);
          req.session.blueprint_name = bp_name.charAt(0).toUpperCase() + bp_name.slice(1);
          return next();
        })
      }catch(e){
        console.error('Unable to get the blueprint name (policies) (try): '+e.message);
        return next();
      }
    });
  }
};