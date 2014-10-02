process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

var kit_ops = require('kit-ops/kit-ops');
var maestro_ldap = require('maestro-users/maestro-users');

kit_ops.get_opt('kit_admin', function(err_ops, result_ops){
  if(err_ops){
    console.log('kit_admin error:'+err_ops);
    process.exit(-1);
  }else{
    if(result_ops !== null){
      var random_pass = Math.random().toString(36).substr(2, 8);
      var user = { full_name: 'kit admin', mail: result_ops, password: random_pass };
      maestro_ldap.add_admin_user(user, function(err, result){
        if(err){
          console.log('unable to add the admin user to the ldap server and move it to the admins group, root cause: '+err);
          process.exit(-1);
        }else{
          if(result){
            console.log('admin account ('+result_ops+') migrated successfuly, new password is: '+random_pass);
            process.exit();
          }else{
            console.log('unable to migrate the admin account ('+result_ops+')');
            process.exit(-1);
          }
        }
      })
    }else{
      console.log('admin account does not exist');
      process.exit(-1);
    }
  }
});