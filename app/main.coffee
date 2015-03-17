version = '?v=2'

cleanUpSpecialChars = (str)->
  str = str.replace(/[àáâãäåă]/gi,"a") # ă, â
  str = str.replace(/[șşṣṩṧš]/gi,"s") # ș
  str = str.replace(/[țƫţṭ]/gi,"t") # ț
  str = str.replace(/[îíǐĭìï]/gi,"i") # î

  return str

unescape = (str)->
  str = str.replace(/\&amp;/g, '&')
  str = str.replace(/\&lt;/g,  '<')
  str = str.replace(/\&gt;/g,  '>')
  str = str.replace(/\&apos;/g,  "'")
  str = str.replace(/\&quot;/g,  '"')

symbolEncodingMap =
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
  '>': 'symbol-bigger'
  '<': 'symbol-smaller'

symbolDecodingMap = {}
for symbol, encoding of symbolEncodingMap
  symbolDecodingMap[encoding] = symbol

controller =
  encodeSymbol: (symbol)->
    if symbol of symbolEncodingMap
      symbolEncodingMap[symbol]
    else
      symbol

  decodeSymbol: (symbol)->
    if symbol of symbolDecodingMap
      symbolDecodingMap[symbol]
    else
      symbol.toUpperCase()

  symbolMaps: {}

  getSymbolMap: ->
    # Create if not created previously
    unless @fontGroup of @symbolMaps
      symbolMap = {}
      for symbol of @getFontsData()[@fontGroup]
        # symbol = symbol
        symbolMap[@decodeSymbol(symbol)] = symbol

      # Cache
      @symbolMaps[@fontGroup] = symbolMap

    return @symbolMaps[@fontGroup]

  isSymbol: (symbol)->
    symbol.toUpperCase() of @getSymbolMap()

  each: (str, cb)->
    i = 0
    while i < str.length
      if i < str.length - 1
        if @isSymbol(str.substr(i, 2))
          cb(str.substr(i, 2))
          i++
        else
          cb(str[i])
      else
        cb(str[i])

      i++

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
    @each text, (symbol)=>
      symbolData = @getSymbolData(symbol, height)
      sum += symbolData.width

    # Add one more space as each word is spaced
    sum += @getSymbolData(' ', height).width

    return sum

  computeLineHeight: (text)->
    # Compute min line height based on widest line
    preliminaryHeight = Infinity
    lines = text.split('\n')

    for line in lines
      lineWidth = @computeWidth line, 100 # Compute character width if its height is 100
      lineHeight = (100 * (@totalWidth / lineWidth))
      preliminaryHeight = Math.min(preliminaryHeight, lineHeight)

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

  writeText: (text=null)->
    # Cache last text
    if text?
      text = text.substr(0, 200)
      @lastText = text
    # If no text, get from cache
    else if @lastText?
      text = @lastText

    text = cleanUpSpecialChars(text)
    text = unescape(text)
    lineHeightRaw = @computeLineHeight(text)
    lineHeight = Math.floor lineHeightRaw
    spriteWidth = @spriteWidth()
    maxCharacterWidth = Math.round @maxCharacterWidthByHeight(lineHeight)
    spaceHalfWidth = Math.floor(@getSymbolData(' ', lineHeight).width / 2)

    newText = "<span style='padding: 0 #{spaceHalfWidth}px;'>" # First tag
    @each text, (symbol)=>
      symbolData = @getSymbolData(symbol, lineHeight)
      symbolOffset = symbolData.index * 240 * maxCharacterWidth / spriteWidth

      if symbolData.symbol is ' '
        newText += "</span><span style='padding: 0 #{spaceHalfWidth}px;'>"
      else if symbolData.symbol is '\n'
        newText += "</span><br><span style='padding: 0 #{spaceHalfWidth}px;'>"
      else
        newText += "<i style='width: #{Math.floor symbolData.width}px; height: #{lineHeight}px;'><img style='width:#{maxCharacterWidth}px;margin-top: -#{symbolOffset}px' src='#{URI_ROOT}public/fonts/#{@fontGroup}/font-sprite.jpg#{version}'></i>"
    newText += '</span>' # Last tag

    @$text.html newText

  listenTextarea: ->
    $message = $('#textarea')
    $message.on 'keyup paste cut change', (el)=>
      @writeText $message.val()

    # Render first message
    # @writeText $message.val()

  listenSelect: ->
    $select = $('#font')
    $select.on 'change', (el)=>
      @fontGroup = $(el.currentTarget).val()

  listenResize: ->
    $(window).on 'resize', =>
      if @resizeTimeout?
        clearTimeout @resizeTimeout

      @resizeTimeout = setTimeout =>
        @computeMessageBoxSizes()
        @writeText()
      , 300

  computeMessageBoxSizes: ->
    @$text.innerHeight
    @totalHeight = @$text.parent().height() - 1
    @totalWidth = @$text.width() - 1 # Browser may ceil a float value

  start: ->
    @$text = $('#message')

    @fontGroup = "font#{PRELOADED_FONT}"
    @minHeight = 34
    @maxHeight = 120
    @computeMessageBoxSizes()

    @writeText PRELOADED_MESSAGE || PRELOADED_MESSAGE_BACKUP
    @listenTextarea()
    @listenSelect()
    @listenResize()

listenForFontChange = (controller)->
  $wrappers = $('.content-wrapper')

  $('body').on 'click', '[data-action="prev-font"]', =>
    currentFont = +controller.fontGroup[controller.fontGroup.length - 1]
    if currentFont is 1
      newFontIndex = 5
    else
      newFontIndex = currentFont - 1

    newFont = "font#{newFontIndex}"

    $wrappers.filter("[data-type='#{newFont}']").addClass('active')
    $('.action-content-inner').animate {left: "-#{(newFontIndex - 1) * 100}%"}, ->
      $wrappers.not("[data-type='#{newFont}']").removeClass('active')
    controller.fontGroup = newFont
    controller.writeText()

  $('body').on 'click', '[data-action="next-font"]', =>
    currentFont = +controller.fontGroup[controller.fontGroup.length - 1]
    if currentFont is 5
      newFontIndex = 1
    else
      newFontIndex = currentFont + 1

    newFont = "font#{newFontIndex}"

    $wrappers.filter("[data-type='#{newFont}']").addClass('active')
    $('.action-content-inner').animate {left: "-#{(newFontIndex - 1) * 100}%"}, ->
      $wrappers.not("[data-type='#{newFont}']").removeClass('active')
    controller.fontGroup = newFont
    controller.writeText()

listenForFromToChange = (controller)->
  $createFrom = $('#create-from') # input
  $editFrom = $('.edit-from')
  $createTo = $('#create-to') # input
  $editTo = $('.edit-to')

  $createFrom.on 'input paste keyup cut change', ->
    if $createFrom.val()
      $editFrom.show().find('strong').text $createFrom.val()
    else
      $editFrom.hide().find('strong').text ''

  $createTo.on 'input paste keyup cut change', ->
    if $createTo.val()
      $editTo.show().find('strong').text $createTo.val()
    else
      $editTo.hide().find('strong').text ''

listenForActionButtons = (controller)->
  emailRegex = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$/i
  $actionCopy = $('[data-action="copy"]')

  $('body').on 'click', '[data-action="edit"]', ->
    $(this).toggleClass("active").siblings('.action-box').toggleClass('active')

  $('body').on 'click', '[data-action="save"]', =>
    # Save on server
    $.ajax
      type: 'POST'
      url: URI_ROOT + 'mesaj'
      data:
        message: controller.lastText
        from: $('#create-from').val()
        to: $('#create-to').val()
        font: controller.fontGroup
      dataType: 'json'
      success: (data)->
        # Scroll footer
        $('.footer-inner').animate {left: '-200%'}, ->
          # Update uri
          history?.pushState?({}, document.title, data.url)
          # Update message id
          window.MESSAGE_ID = data.url.substr(data.url.lastIndexOf('/') + 1)
          # Update share link
          $actionCopy
            .attr('data-clipboard-text', URI_ROOT + 'mesaj/' + MESSAGE_ID)

  $('body').on 'click', '[data-action="try"]', (ev)=>
    ev.preventDefault()
    $('.footer-inner').animate {left: '-100%'}, ->
      history?.pushState?({}, document.title, URI_ROOT)
      $('#create-from').val('').trigger('change')
      $('#create-to').val('').trigger('change')
      $('#textarea').val(PRELOADED_MESSAGE_BACKUP).trigger('change')

  copyInstance = new ZeroClipboard(document.getElementById("copy-button"))

  copyInstance.on "ready", ( readyEvent )->
    copyInstance.on "aftercopy", ( event )->
      $actionCopy.siblings('.action-box').addClass('active')
      setTimeout ->
        $actionCopy.siblings('.action-box').removeClass('active')
      , 1500

  $actionCopy
    .attr('data-clipboard-text', URI_ROOT + 'mesaj/' + MESSAGE_ID)

  $actionShare = $('[data-action="share"]')
  $actionShare.on 'click', (ev)->
    ev.preventDefault()

    winWidth = 520
    winHeight = 510
    winTop = ($(window).height() / 2) - (winHeight / 2)
    winLeft = ($(window).width() / 2) - (winWidth / 2)

    # title = 'Mesaje Dulci'
    title = ''
    # descr = 'Alege-ți zahărul brun preferat și scrie un mesaj dulce celor dragi!'
    descr = ''
    url = URI_ROOT + 'mesaj/' + MESSAGE_ID
    # image = URI_ROOT + 'public/img/fb-cover.jpg'
    image = ''
    window.open('http://www.facebook.com/sharer.php?s=100&p[title]=' + title + '&p[summary]=' + descr + '&p[url]=' + url + '&p[images][0]=' + image, 'sharer', 'top=' + winTop + ',left=' + winLeft + ',toolbar=0,status=0,width=' + winWidth + ',height=' + winHeight);

$ ->
  $preload = $('.preload')
  $preloadProgress = $('.preload-progress-done')

  $preloadProgress.animate {width: '95%'}, 10000
  # Preload first image
  $.preload "#{URI_ROOT}public/fonts/font#{PRELOADED_FONT}/font-sprite.jpg#{version}", ->
    $preloadProgress.stop().animate {width: '100%'}, 500, ->
      $preload.hide()
      controller.start()
      listenForFontChange controller
      listenForFromToChange controller
      listenForActionButtons controller

    # Preload other fonts
    fontSprites = []
    for i in [1..5]
      fontSprites.push "#{URI_ROOT}public/fonts/font#{i}/font-sprite.jpg#{version}"
    $.preload fontSprites, ->
      # console.log 'all fonts preloaded'
