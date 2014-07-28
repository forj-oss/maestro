module.exports = {
 authenticate: function(req, callback){
   //For Keystone we need the username and password
   var usr = req.body.username;
   var pass = req.body.password;
   
   //TODO: we do the authentication with the required fields and stuff
   
   callback(null, null , true);
 }
}