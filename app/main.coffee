controller =
  getSymbolMap: ->
    unless @_symbolMap
      @_symbolMap =
        '-': 'symbol-minus'
        ',': 'symbol-comma'
        '.': 'symbol-dot'
        '+': 'symbol-plus'
        '(': 'symbol-left-parantheses'
        ')': 'symbol-right-parantheses'
        '?': 'symbol-question'
        '!': 'symbol-exclamation'
        ':': 'symbol-column'

      for i in [0..9]
        @_symbolMap["#{i}"] = "#{i}"

      for i in [65..90]
        char = String.fromCharCode(i)
        @_symbolMap[char] = char

    return @_symbolMap

  getSymbolFontData: (symbol)->
    symbolMap = @getSymbolMap()
    fontsData = @getFontsData()
    fontsData[@fontGroup + '/' + symbolMap[symbol] + '.jpg']

  getSymbolData: (symbol, height)->
    symbolMap = @getSymbolMap()
    data =
      src: ''
      width: 0
      height: height

    # Uppercase
    symbol = symbol.toUpperCase()

    if symbol is ' '
      data.src = 'fonts/transparent.gif'
      data.width = Math.floor height/3
    else
      unless symbol of symbolMap
        symbol = '?'

      symbolFontData = @getSymbolFontData symbol
      data.width = Math.floor(height * symbolFontData.sizeRatio)
      data.src = "fonts/#{@fontGroup}/#{symbolMap[symbol]}.jpg"

    data.symbol = symbol

    return data

  loadFontsData: (cb)->
    $.ajax
      url: 'js/fonts.json'
      dataType: 'json'
      success: (@_fontsData)=>
        # Compute size ratio
        @_fontsData = _.mapValues @_fontsData, (value, key)->
          value.sizeRatio = value.width / value.height
          value

        cb(@_fontsData)
      error: (jqXHR, textStatus)->
        alert textStatus

  getFontsData: (cb)->
    # Do we need a clone?
    @_fontsData

  writeText: (text)->
    count = text.length
    minHeight = 34
    maxHeight = 100

    height = Math.min(maxHeight, Math.max(minHeight, 650/count))
    spaceHalfWidth = Math.floor(height/6)

    @$text.empty()
    newText = "<span style='padding: 0 #{spaceHalfWidth}px;'>" # First tag
    _.each text.split(''), (symbol)=>
      symbolData = @getSymbolData(symbol, height)
      if symbolData.symbol is ' '
        newText += "</span><span style='padding: 0 #{spaceHalfWidth}px;'>"
      else
        newText += "<img src='#{symbolData.src}' style='height: #{symbolData.height}px; width: #{symbolData.width}px'>"
    newText += '</span>' # Last tag

    @$text.html newText


  listenTextarea: ->
    $message = $('#message')
    $message.on 'keyup paste change', (el)=>
      @writeText $message.val()
      console.log $message.val()

  start: ->
    @loadFontsData =>
      @$text = $('#text')
      @fontGroup = 'font1'
      @listenTextarea()

$ ->
  controller.start()
