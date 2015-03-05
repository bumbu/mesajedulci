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
    @getFontsData()[@fontGroup][symbolMap[symbol]]

  getSymbolData: (symbol, height)->
    symbolMap = @getSymbolMap()
    data =
      src: ''
      width: 0
      height: height
      index: 0

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
      data.src = "#{URI_ROOT}public/fonts/#{@fontGroup}/#{symbolMap[symbol]}.jpg"
      data.index = symbolFontData.index

    data.symbol = symbol

    return data

  getFontsData: ->
    unless @_fontsData?
      @_fontsData = jQuery.parseJSON(FONTS_DATA)

      # Process data
      for fontGroupName, fontGroup of @_fontsData
        for symbolAlias, symbolData of fontGroup
          symbolData.sizeRatio = symbolData.width / symbolData.height

    @_fontsData

  computeWidth: (text, height=100)->
    sum = 0
    _.each text.split(''), (symbol)=>
      symbolData = @getSymbolData(symbol, height)
      sum += symbolData.width
    return sum

  computeLineHeight: (text)->
    # Compute min line height based on widest line
    lines = text.split('\n')
    preliminaryHeight = _.reduce lines, (prev, line)=>
      lineWidth = @computeWidth line, 100 # Compute character width if its height is 100
      lineHeight = (100 * (@totalWidth / lineWidth))
      return if lineHeight < prev then lineHeight else prev
    , Infinity

    # Compute height based on number of rows
    preliminaryHeight = Math.min preliminaryHeight, @totalHeight / lines.length

    # Check if height matches limits
    height = Math.min(@maxHeight, Math.max(@minHeight, preliminaryHeight))

  spriteWidth: ->
    max = 0
    for symbolName, symbolData of @getFontsData()[@fontGroup]
      max = Math.max(max, symbolData.width)

    return max

  maxCharacterWidthByHeight: (height)->
    max = 0
    for symbolName, symbolData of @getFontsData()[@fontGroup]
      max = Math.max(max, symbolData.sizeRatio * height)

    return max

  writeText: (text)->
    lineHeightRaw = @computeLineHeight(text)
    lineHeight = Math.floor lineHeightRaw
    spriteWidth = @spriteWidth()
    maxCharacterWidth = Math.round @maxCharacterWidthByHeight(lineHeight)
    spaceHalfWidth = Math.floor(@getSymbolData(' ', lineHeight).width / 2)

    newText = "<span style='padding: 0 #{spaceHalfWidth}px;'>" # First tag
    _.each text.split(''), (symbol)=>
      symbolData = @getSymbolData(symbol, lineHeight)
      mh = symbolData.index * 240 * maxCharacterWidth / spriteWidth

      if symbolData.symbol is ' '
        newText += "</span><span style='padding: 0 #{spaceHalfWidth}px;'>"
      else if symbolData.symbol is '\n'
        newText += "</span><br><span style='padding: 0 #{spaceHalfWidth}px;'>"
      else
        newText += "<i style='width: #{Math.floor symbolData.width}px; height: #{lineHeight}px;'><img style='width:#{maxCharacterWidth}px;margin-top: -#{mh}px' src='#{URI_ROOT}public/fonts/#{@fontGroup}/font-sprite.jpg'></i>"
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

    @$text = $('#message')
    @fontGroup = 'font1'
    @listenTextarea()
    @listenSelect()

    #TODO remove me
    # @writeText 'Supărările iubirii\nSunt ca ploile cu soare:\nRepezi, cu cât mai repezi\nCu atât mai trecătore.'
    # @writeText 'Alege-ți zahărul brun preferat și scrie un mesaj dulce celor dragi!'
    @writeText '0123456789 abcdefghijklmnopqrs :.,=!(-+?)* tuvwxyz'

$ ->
  controller.start()
