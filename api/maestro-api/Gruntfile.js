/**
*# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
*#
*#   Licensed under the Apache License, Version 2.0 (the "License");
*#   you may not use this file except in compliance with the License.
*#   You may obtain a copy of the License at
*#
*#       http://www.apache.org/licenses/LICENSE-2.0
*#
*#   Unless required by applicable law or agreed to in writing, software
*#   distributed under the License is distributed on an "AS IS" BASIS,
*#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*#   See the License for the specific language governing permissions and
*#   limitations under the License.
*/
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
