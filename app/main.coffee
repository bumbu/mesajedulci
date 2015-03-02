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
        '*': 'symbol-star'
        '=': 'symbol-equal'

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
      data.width = Math.floor height/3
    else if symbol is '\n'
      data.width = 0
    else
      unless symbol of symbolMap
        symbol = '?'

      symbolFontData = @getSymbolFontData symbol
      data.width = height * symbolFontData.sizeRatio # Do not round as we need precision
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

  computeWidth: (text, height=100)->
    sum = 0
    _.each text.split(''), (symbol)=>
      symbolData = @getSymbolData(symbol, height)
      sum += symbolData.width
    return sum

  computeHeight: (text)->
    # Compute min line height based on widest line
    lines = text.split('\n')
    preliminaryHeight = _.reduce lines, (prev, line)=>
      lineWidth = @computeWidth line, 100 # Compute character width if its height is 100
      lineHeight = Math.floor(100 * (@totalWidth / lineWidth))
      return if lineHeight < prev then lineHeight else prev
    , Infinity

    # Compute height based on number of rows
    preliminaryHeight = Math.min preliminaryHeight, @totalHeight / lines.length

    # Check if height matches limits
    height = Math.floor Math.min(@maxHeight, Math.max(@minHeight, preliminaryHeight))

  writeText: (text)->
    height = @computeHeight(text)
    spaceHalfWidth = Math.floor(@getSymbolData(' ', height).width / 2)

    newText = "<span style='padding: 0 #{spaceHalfWidth}px;'>" # First tag
    _.each text.split(''), (symbol)=>
      symbolData = @getSymbolData(symbol, height)
      if symbolData.symbol is ' '
        newText += "</span><span style='padding: 0 #{spaceHalfWidth}px;'>"
      else if symbolData.symbol is '\n'
        newText += "</span><br><span style='padding: 0 #{spaceHalfWidth}px;'>"
      else
        newText += "<img src='#{symbolData.src}' style='height: #{symbolData.height}px; width: #{Math.floor symbolData.width}px'>"
    newText += '</span>' # Last tag

    @$text.html newText
    @$text.css
      'margin-left': -spaceHalfWidth
      'margin-right2': -spaceHalfWidth

  listenTextarea: ->
    $message = $('#message')
    $message.on 'keyup paste change', (el)=>
      @writeText $message.val()
      console.log $message.val()

    # Render first message
    @writeText $message.val()

  listenSelect: ->
    $select = $('#font')
    $select.on 'change', (el)=>
      @fontGroup = $(el.currentTarget).val()

  start: ->
    @minHeight = 34
    @maxHeight = 100
    @totalHeight = 255
    @totalWidth = 486

    @loadFontsData =>
      @$text = $('#message')
      @fontGroup = 'font1'
      @listenTextarea()
      @listenSelect()

      #TODO remove me
      @writeText 'Supărările iubirii\nSunt ca ploile cu soare:\nRepezi, cu cât mai repezi\nCu atât mai trecătore.'

$ ->
  controller.start()
