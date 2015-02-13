var async = require('async');
var ldap = require('ldapjs');
var redis = require('redis');
var crypto = require('crypto');
var validator = require('validator');
var kit_ops = require('../../../node_modules/kit-ops/kit-ops');
var cryptoUtil = require('../../../node_modules/crypto-util/crypto-util');
var check_grav = require('../../../node_modules/check-grav/check-grav');
var blueprint_utils = require('../../../node_modules/blueprint/blueprint');
var config = require('./config');


module.exports = {
  authenticate: function(req, callback){
    
    //Username = email
    var user = req.body.username;
    var password = cryptoUtil.encrypt(req.body.password);
    
    if(validator.isEmail(user)){
      get_service_account(function(err, account){
        if(err){
          callback(err, null, null);
        }else{
          
          process.env.NODE_TLS_REJECT_UNAUTHORIZED = 0;
          var client = ldap.createClient({
            url: account.server
          });
          
          async.series({
            authenticated: function(callback_){
              client.bind('uid=' + user + ',ou=people,' + account.dit, password, function(err_bind){
                if(err_bind){
                  callback_(null, false);
                }else{
                  client.unbind(function(err_unb){
                    if(err_unb){
                      console.log('ldap module error (Unbind, authenticated): ' + err_unb) ;
                    }
                  });
                  callback_(null, true);
                }
              });
            },
            email: function(callback_){
              callback_(null, user);
            },
            gravatar_hash: function(callback_){
              callback_(null, crypto.createHash('md5').update(user).digest('hex'));
            },
            has_gravatar: function(callback_){
              check_grav.gravatar_exist(crypto.createHash('md5').update(user).digest('hex'), function(has_grav){
                callback_(null, has_grav);
              });
            },
            kit_has_admin: function(callback_){
              get_members_of('admins', function(err_mem, members){
                if(err_mem){
                  console.log('ldap module error (get members of admin, kit_has_admin): '+err_mem)
                }else{
                  if(members.length > 0){
                    callback_(null, true);
                  }else{
                    callback_(null, false);
                  }
                }
              });
            },
            is_admin: function(callback_){
              get_members_of('admins', function(err_mem, members){
                if(err_mem){
                  console.log('ldap module error (get members of admin, kit_has_admin): '+err_mem)
                }else{
                  if(members.length < 0){
                    callback_(null, false);
                  }else{
                    var is_adm = (members.indexOf(user) !== -1) ? true : false;
                    callback_(null, is_adm);
                  }
                }
              });
            },
            project_visibility: function(callback_){
              callback_(null, null);
            }
          }, function(async_err, async_result) {
            if (async_err) {
              console.error('Async error: ' + async_err.message);
              callback(async_err, null, null);
            }else{
              if(async_result.kit_has_admin === false){
                
                async_result.project_visibility = projectsVisibility(async_result.is_admin, async_result.authenticated, req.session.global_manage_projects);
                callback(null, null, async_result);
                
              }else{
                
                async_result.project_visibility = projectsVisibility(async_result.is_admin, async_result.authenticated, req.session.global_manage_projects);
                callback(null, null, async_result);
                
              }
            }
          });
          
          
        }
      });
    }else{
      callback('Username has to be a valid email', null, null);
    }
  }
}


function get_service_account(callback){
  client = redis.createClient();

  client.on('error', function(err){
    callback(err, null);
  });

  client.select(config.redisdb, function(){
    
    async.series({
      user: function(callback_result){
        client.get('ldap_sa_user', function(err, reply){
          if(err){
            callback_result(err, null);
          }else{
            callback_result(null, reply );
          }
        })
      },
      password: function(callback_result){
        client.get('ldap_sa_password', function(err, reply){
          if(err){
            callback_result(err, null);
          }else{
            callback_result(null, reply );
          }
        })
      },
      server: function(callback_result){
        client.get('ldap_server', function(err, reply){
          if(err){
            callback_result(err, null);
          }else{
            callback_result(null, reply );
          }
        })
      },
      dit: function(callback_result){
        client.get('ldap_dit', function(err, reply){
          if(err){
            callback_result(err, null);
          }else{
            callback_result(null, reply );
          }
        })
      }
    }, function(err, results){
      //UPSTREAM RESULTS
      if(err){
        callback(err, null);
      }else{
        callback(null, results);
      }
    });
    
  });
}


function get_members_of(group, callback){
  get_service_account(function(err, account){
    if(err){
      callback(err, null);
    }else{
      
      process.env.NODE_TLS_REJECT_UNAUTHORIZED = 0;
      var client = ldap.createClient({
        url: account.server
      })
      
      client.bind(account.user, account.password, function(err_bind) {
        if(err_bind){
          callback(err_bind, null);
        }else{
          
          var records = [];
          
          var opt = {
            filter: 'cn='+group,
            scope: 'sub'
          };
          
          client.search('ou=groups,'+account.dit, opt, function(err_srch, res){
            if(err_srch){
              console.log('error search: '+err_srch);
              client.unbind(function(err_unbind) {
                if(err_unbind){
                  console.log('LDAP unbind error: '+err_unbind);
                }
              })
            }else{
              res.on('searchEntry', function(entry) {
                member = entry.object.member;
                if(member){
                  if(Array.isArray(member)){
                    member.forEach(function(member){
                      if(member.substr(0,4) === 'uid='){
                        member = member.split(',')[0].replace('uid=','');
                        records.push(member);
                      }
                    })
                  }else{
                    if(member.substr(0,4) === 'uid='){
                      member = member.split(',')[0].replace('uid=','');
                      records.push(member);
                    }
                  }
                }
              });
              res.on('error', function(err_search) {
                console.error('LDAP failed to retrieve the members of '+group+': ' + err_search.message);
                client.unbind(function(err_unbind) {
                  if(err_unbind){
                    console.log('LDAP unbind error: '+err_unbind);
                  }
                });
                callback(err_search, null);
              });
              res.on('end', function(result) {
                client.unbind(function(err_unbind) {
                  if(err_unbind){
                    console.log('LDAP unbind error: '+err_unbind);
                  }
                });
                callback(null, records);
              });
            }
          });
          
        }
      })
    }
  })
}


function projectsVisibility(is_admin, is_authenticated, global_manage_projects){
  var anonymous = 'anonymous';
  var authenticated = 'authenticated';
  if(is_admin){
    return true;
  }else{
    if(global_manage_projects !== null){
      if(global_manage_projects === anonymous){
        return true
      } else if(global_manage_projects === authenticated && is_authenticated === true){
        return true;
      }else{
        return false;
      }
    }else{
      return false;
    }
  }
}