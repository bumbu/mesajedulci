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
imagesDataProcess = (fontsFolder, jsonFileLocation) -> ()->
  fontsData = {}

  # Find font groups
  fontGroups = []
  for symbolKey, symbolData of imagesJSON
    fontGroup = symbolKey.substr(0, symbolKey.indexOf('/'))
    unless fontGroup in fontGroups
      fontGroups.push fontGroup
      fontsData[fontGroup] = {} # Init fonts data arrays

  for fontGroup in fontGroups
    fontGroupFolder = "#{fontsFolder}/#{fontGroup}"
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

  fs.writeFile jsonFileLocation, JSON.stringify(fontsData), ->
    console.log "Image data saved into #{jsonFileLocation}"

imagesProcess = (fontsFolder, imageHeight)-> ()->
  # Clean old directory
  fs.readdirSync(fontsFolder)
    .filter (folder)->
      fs.lstatSync(path.join(fontsFolder, folder)).isDirectory()
    .forEach (folder)->
      fs.readdirSync(path.join(fontsFolder, folder))
        .filter (file)->
          fs.lstatSync(path.join(fontsFolder, folder, file)).isFile()
        .forEach (file)->
          console.log path.join(fontsFolder, folder, file)
          try
            fs.unlinkSync path.join(fontsFolder, folder, file)
          catch e
            console.log e

  gulp.src './app/fonts/**/*.jpg'
    .pipe through.obj (file, enc, cb)->
      tmpFilePath = "./app/tmp/#{randomString(16)}"

      easyimage.resize
        src: file.path
        dst: tmpFilePath
        height: imageHeight
        width: imageHeight * 10 # Set width excesively large so that resize is done by height
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
    .pipe gulp.dest fontsFolder

imagesPublicSprites = ->
  fontsFolder = './public/fonts/'

  folders = fs.readdirSync(fontsFolder).filter (folder)->
    fs.lstatSync(fontsFolder + folder).isDirectory()

  # Delete old files
  folders.forEach (folder)->
    spritePath = "#{fontsFolder}#{folder}/font-sprite.jpg"
    try
      fs.unlinkSync spritePath
    catch e
      console.log e

  promisses = []
  folders.forEach (folder)->
    folderPath = "#{fontsFolder}#{folder}/"

    deferred = Q.defer()
    exec 'convert', ["#{folderPath}*.jpg", '-quality', 40, '-background', '#efebe2', '-append', "#{folderPath}font-sprite.jpg"], (err, stdout, stderr)->
      if err?
        deferred.reject err
      else
        deferred.resolve()

      console.log folderPath + ' done'

    promisses.push deferred.promise

  Q.all(promisses)
  .then ->
    console.log 'Joinging symbols done'

gulp.task 'images-process-client', imagesProcess('./public/fonts', 240)
gulp.task 'images-process-server', imagesProcess('./public/fonts-server', 120)

gulp.task 'images-client', ['images-process-client'], imagesDataProcess('./public/fonts', './public/js/fonts.json')
gulp.task 'images-server', ['images-process-server'], imagesDataProcess('./public/fonts-server', './fonts-server.json')

# Compile images for FE use
gulp.task 'client', ['images-client'], imagesPublicSprites

# Generate public sprites
gulp.task 'client-sprites', imagesPublicSprites

# Compile images for BE use
gulp.task 'server', ['images-server']
