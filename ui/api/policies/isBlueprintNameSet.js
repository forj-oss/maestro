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
        blueprint_utils.get_blueprint_section(result.id, 'blueprint_name', function(err){
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