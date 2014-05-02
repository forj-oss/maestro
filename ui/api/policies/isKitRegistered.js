var register_module = require('kit-reg/kit-reg');
module.exports = function(req, res, next){
  register_module.is_registered(function(err){
    console.error('Unable to check if the kit is registered (iskitregistered): '+err.message);
    req.session.kit_registered = { registered: false , error: err.message };
    return next();
  }, function(result){
    req.session.kit_registered = { registered: result.result!==0?false:true, error: null };
    return next();
  })
};