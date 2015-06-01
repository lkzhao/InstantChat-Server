
module.exports = (grunt) ->
  grunt.initConfig
    less:
      compile:
        options: {}
        files:
          "public/stylesheets/main.css": "websrc/less/main.less"
    express:
      options: 
        script: "index.coffee"
        opts: ["/usr/local/bin/coffee"]
      dev:
        options:
          node_env: "development"
      prod:
        options:
          node_env: "production"
    browserify:
      compile:
        src: "websrc/view/main.cjsx"
        dest: "public/javascripts/main.js"
        options:
          browserifyOptions:
            debug: true
            transform: ["coffee-reactify"]
            extensions: [".coffee", ".cjsx"]
    watch:
      less:
        files: ["websrc/less/*.less"]
        tasks: ["less"]
        options:
          spawn: false
      scripts:
        files: ["websrc/view/*.cjsx", "websrc/util/*.coffee"]
        tasks: ["browserify"]
        options:
          spawn: false
      express:
        files:  [ "server.js", "models/*.js" ]
        tasks:  [ "express:dev" ]
        options:
          spawn: false
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-express-server"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-browserify"
  grunt.registerTask "default", ["less", "browserify", "express:dev", "watch"]
