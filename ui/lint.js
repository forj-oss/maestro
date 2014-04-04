var LintRoller = require('lintroller');

var config = {
    verbose          : false,
    stopOnFirstError : false,

    logFile    : {
        name : './error.log',
        type : 'text'
    },

    //recursively include JS files in these folders
    filepaths  : [
        './'
    ],

    //but ignore anything in these folders
    exclusions : [
        './node_modules/',
        './assets/',
        './docs/',
        './config/'
    ],

    linters : [
        {
            type : 'jsHint',
            options : {
	          node : true,
              strict : true,
              maxlen : 100,
              curly  : true,
              undef  : true,
              unused : true,
              indent : 2,
              newcap : true,
              boss   : false,
              lastsemic : false
   	    }        
	}	
    ]
};

LintRoller.init(config);
