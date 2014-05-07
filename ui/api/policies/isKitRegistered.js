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
var register_module = require('kit-reg/kit-reg');
module.exports = function(req, res, next){
  register_module.is_registered(function(err){
    console.error('Unable to check if the kit is registered (iskitregistered): '+err.message);
    req.session.kit_registered = { registered: false , error: err.message };
    return next();
  }, function(result){
    req.session.kit_registered = { registered: result.result!=='0'?true:false, error: null };
    return next();
  })
};