'use strict';

module.exports = function(grunt) {

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    jshint: {
      files: ['Gruntfile.js', 'middleware/**/*.js', 'plugins/**/*.js',  'helpers/**/*.js', 'test/**/*.js'],
      options: { jshintrc: '.jshintrc' }
    },
    apidoc: {
      'maestro-api': {
        src: 'middleware/v1.0',
        dest: 'apidoc/',
        options: {
          debug: true,
          includeFilters: [ '.*\\.js$' ],
          excludeFilters: [ 'node_modules/', 'plugins', 'test' ],
          marked: {
            gfm: true
          }
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-apidoc');

  grunt.registerTask('lint', ['jshint']);
  grunt.registerTask('doc', ['apidoc']);

  /*for now the only task, so make it default */
  grunt.registerTask('default', ['jshint']);

};
