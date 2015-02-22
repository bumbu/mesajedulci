gulp = require 'gulp'
defineModule = require 'gulp-define-module'
coffee = require 'gulp-coffee'
merge = require 'merge-stream'
easyimage = require 'easyimage'
through = require 'through2'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
# Helpers
randomString = (length=8)->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length
# Variables
publicFolder = './public'
vendorMap =
  # jQuery
  './node_modules/jquery/dist/jquery.js': 'jquery.js'
  # Utilities
  './node_modules/lodash/dist/lodash.js': 'lodash.js'


# ########################
# Watching
# ########################

gulp.task 'default', ['watchFiles']
gulp.task 'watchFiles', ['development'], ->
  # Watch script changes
  watcher_script = gulp.watch ['./app/**/*.coffee'], ['development-script']
  watcher_script.on 'change', (e)->
    console.log "#{e.type} #{e.path}"

# ########################
# Development
# ########################

gulp.task 'development', ['development-script', 'development-vendor']

# Build scripts
gulp.task 'development-script', ->
  gulp.src './app/**/*.coffee'
    .pipe coffee({bare: true, join: true})
    .pipe gulp.dest "#{publicFolder}/js"

# Copy vendor files into public folder
gulp.task 'development-vendor', ->
  mergedStream = merge()

  for key, value of vendorMap
    mergedStream.add(
      gulp.src(key)
        # .pipe(rename(value))
        .pipe gulp.dest "#{publicFolder}/js/vendor/"
    )

  # Copy vendor customized code
  mergedStream.add(
    gulp.src './app/vendor/**/*.js'
      .pipe gulp.dest "#{publicFolder}/js/vendor"
  )

  return mergedStream

# ########################
# Images processing
# ########################
imagesJSON = {}
gulp.task 'images', ['images-process'], ->
  fs.writeFile './public/js/fonts.json', JSON.stringify(imagesJSON), ->
    console.log 'Image data saved into fonts.json'

gulp.task 'images-process', ->
  gulp.src './app/fonts/**/*.jpg'
    .pipe through.obj (file, enc, cb)->
      tmpFilePath = "./app/tmp/#{randomString(16)}"

      easyimage.resize
        src: file.path
        dst: tmpFilePath
        height: 400
        quality: 80
      .then (image)->
        # Read image data
        shortName = _.last(file.path.split(path.sep).slice(0, -1)) + '/' + path.basename(file.path)
        imagesJSON[shortName] = _.pick image, 'width', 'height'

        # Pass processed image forward
        fs.readFile tmpFilePath, (err, data)->
          if err then return cb(new Error 'Reading processed file failed')

          # Copy contents into file
          file.contents = data

          # Delete tmp file
          fs.unlinkSync tmpFilePath

          # Log
          console.log "#{shortName} converted"

          # Move forward
          cb(null, file)
      , (err)->
        console.log err
        cb()
    .pipe gulp.dest './public/fonts'
