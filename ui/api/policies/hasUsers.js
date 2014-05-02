var blueprint_utils = require('blueprint/blueprint');
module.exports = function(req, res, next) {

  // User is allowed, proceed to the next policy,
  // or if this is the last policy, the controller
  blueprint_utils.get_blueprint_id(function(error){
    console.error('Unable to get the instance_id of the kit (hasusers): '+error.message);
    req.session.users = false;
    return next();
  }, function(result){
    result = JSON.parse(result);
    blueprint_utils.get_blueprint_section(result.id, 'users', function(err){
      console.error('Unable to check if maestro has users enabled: '+err.message);
      req.session.users = false;
      return next();
    }, function(users){
      users = JSON.parse(users);
      req.session.users = users!==0?true:false;
      return next();
    })
  });
};