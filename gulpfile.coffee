gulp = require 'gulp'
defineModule = require 'gulp-define-module'
coffee = require 'gulp-coffee'
merge = require 'merge-stream'
easyimage = require 'easyimage'
through = require 'through2'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
exec = require('child_process').execFile
Q = require('q')
stylus = require('gulp-stylus')
nib = require('nib')
livereload = require('gulp-livereload')
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
  livereload.listen auto: true
  # Watch script changes
  watcher_script = gulp.watch ['./app/**/*.coffee'], ['development-script']
  watcher_script.on 'change', (e)->
    console.log "#{e.type} #{e.path}"

  # Watch style changes
  watcher_style = gulp.watch('./app/css/**/*.styl', ['development-style'])
  watcher_style.on 'change', (e)->
    console.log "#{e.type} #{e.path}"

# ########################
# Development
# ########################

gulp.task 'development', ['development-script', 'development-vendor', 'development-style']

# Build scripts
gulp.task 'development-script', ->
  gulp.src './app/**/*.coffee'
    .pipe coffee({bare: true, join: true})
    .pipe gulp.dest "#{publicFolder}/js"
    .pipe livereload auto: false

gulp.task 'development-style', ->
  gulp.src('./app/css/style.styl')
    .pipe(stylus({use: [nib()], 'include css': true, url: {name: 'url', limit: 32768, paths: [__dirname + '/public/img']}}))
    .pipe(gulp.dest('./public/css'))
    .pipe livereload auto: false

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
  fontsData = {}

  # Find font groups
  fontGroups = []
  for symbolKey, symbolData of imagesJSON
    fontGroup = symbolKey.substr(0, symbolKey.indexOf('/'))
    unless fontGroup in fontGroups
      fontGroups.push fontGroup
      fontsData[fontGroup] = {} # Init fonts data arrays

  for fontGroup in fontGroups
    fontGroupFolder = "./public/fonts/#{fontGroup}"
    fontGroupFiles = fs.readdirSync(fontGroupFolder).filter (file)->
      "#{fontGroup}/#{file}" of imagesJSON

    fontGroupFiles = fontGroupFiles.sort (a, b)->
      if a.charCodeAt(0) <= 57
        a = parseInt(a, 10)
      if b.charCodeAt(0) <= 57
        b = parseInt(b, 10)

      if _.isNumber(a) and _.isNumber(b)
        a - b
      else if _.isNumber(a)
        -1
      else if _.isNumber(b)
        1
      else
        a.toLowerCase().localeCompare b.toLowerCase()

    index = -1
    for file in fontGroupFiles
      index++
      symbolData = imagesJSON["#{fontGroup}/#{file}"]
      symbol = file.substr(0, file.lastIndexOf('.'))

      fontsData[fontGroup][symbol] =
        width: symbolData.width
        height: symbolData.height
        index: index

  fs.writeFile './public/js/fonts.json', JSON.stringify(fontsData), ->
    console.log 'Image data saved into fonts.json'

gulp.task 'images-process', ->
  gulp.src './app/fonts/**/*.jpg'
    .pipe through.obj (file, enc, cb)->
      tmpFilePath = "./app/tmp/#{randomString(16)}"

      easyimage.resize
        src: file.path
        dst: tmpFilePath
        height: 240
        width: 1000 # Set is excesively large so that resize is done by height
        quality: 100
      .then (image)->
        # Read image data
        fontGroup = _.last(file.path.split(path.sep).slice(0, -1))
        symbol = path.basename(file.path, path.extname(file.path))

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

gulp.task 'images-sprite', ->
  publicFontsFolder = './public/fonts/'

  folders = fs.readdirSync(publicFontsFolder).filter (folder)->
    fs.lstatSync(publicFontsFolder + folder).isDirectory()

  # Delete old files
  folders.forEach (folder)->
    spritePath = "#{publicFontsFolder}#{folder}/font-sprite.jpg"
    fs.unlinkSync spritePath

  promisses = []
  folders.forEach (folder)->
    folderPath = "#{publicFontsFolder}#{folder}/"

    deferred = Q.defer()
    exec 'convert', ["#{folderPath}*.jpg", '-quality', 40, '-background', '#efebe2', '-append', "#{folderPath}font-sprite.jpg"], (err, stdout, stderr)->
      if err?
        deferred.reject err
      else
        deferred.resolve()

      console.log folderPath + ' done'

    promisses.push deferred.promise
    # console.log "convert #{folderPath}*.jpg -background #eeebdf -append #{folderPath}font-sprite.jpg"
    # easyimage.exec "convert #{folderPath}*.jpg -background #eeebdf -append #{folderPath}font-sprite.jpg"

  Q.all(promisses)
  .then ->
    console.log 'Joinging symbols done'

    convArgs = []
    folders.forEach (folder)->
      convArgs.push "#{publicFontsFolder}#{folder}/font-sprite.jpg"
    convArgs = convArgs.concat ['-background', '#efebe2', '-quality', 40, '+append', "#{publicFontsFolder}fonts-sprite.jpg"]
    console.log convArgs

    exec 'convert', convArgs, (err, stdout, stderr)->
      console.log 'Joining fonts done'
