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
var kit_ops = require('kit-ops/kit-ops');

module.exports = function(req, res, next) {

  // User is allowed, proceed to the next policy,
  // or if this is the last policy, the controller
  if (req.session.show_welcome_message) {
    return next();
  }else{
    kit_ops.get_opt('show_welcome_notification', function(err, identifier){
      if(err){
        console.error('Unable to check if the welcome message should be shown (hasWelcomeMessage): '+err.message);
      }else{
        var notificationValue = identifier.option_value;
        req.session.show_welcome_message = notificationValue;
      }
      return next();
    });    
  }
};
