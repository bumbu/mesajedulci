version = '?v=' + window.VERSION

###
  Accents
  \u0306 - breve
  \u030C - caron (used wrongly as breve)
  \u0302 - circumflex
  \u0326 - comma below
  \u0327 - cedilla below


  \u0102 - a breve
  \u00C2 - a circumflex
  \u00CE - i circumflex
  \u0218 - s comma below
  \u021A - t comma below
###

cleanUpSpecialChars = (str)-> str

if window.LANGUAGE is 'ro'
  cleanUpSpecialChars = (str)->
    str = str
      .replace(/[àáãäåă]/gi,"\u0102") # ă
      .replace(/a\u0306/gi,"\u0102") # ă breve
      .replace(/a\u030C/gi,"\u0102") # ă caron
      .replace(/a\u0302/gi,"\u00C2") # â circumflex
      .replace(/[îíǐĭìï]/gi,"\u00CE") # î
      .replace(/[șşṣṩṧš]/gi,"\u0218") # ș
      .replace(/s\u0326/gi,"\u0218") # ș comma
      .replace(/s\u0327/gi,"\u0218") # ș cedilla
      .replace(/[țƫţṭ]/gi,"\u021A") # ț
      .replace(/t\u0326/gi,"\u021A") # ț comma
      .replace(/t\u0327/gi,"\u021A") # ț cedilla

    return str

unescape = (str)->
  str = str.replace(/\&amp;/g, '&')
  str = str.replace(/\&lt;/g,  '<')
  str = str.replace(/\&gt;/g,  '>')
  str = str.replace(/\&apos;/g,  "'")
  str = str.replace(/\&quot;/g,  '"')

symbolEncodingMap = {}

if window.LANGUAGE is 'ro'
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
    '\u0102': 'accent-a-breve'
    '\u00C2': 'accent-a-circumflex'
    '\u00CE': 'accent-i-circumflex'
    '\u0218': 'accent-s-comma'
    '\u021A': 'accent-t-comma'

else if window.LANGUAGE is 'ru'
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
    'Б': 'accent-b'
    'Ю': 'accent-iu'
    'Ь': 'accent-soft'
    'Ч': 'accent-ch'
    'Ж': 'accent-j'
    'Ъ': 'accent-strong'
    'Д': 'accent-d'
    'К': 'accent-k'
    'Т': 'accent-t'
    'Е': 'accent-e'
    'Л': 'accent-l'
    'Ц': 'accent-ts'
    'Я': 'accent-ea'
    'М': 'accent-m'
    'У': 'accent-u'
    'Ё': 'accent-eo'
    'Н': 'accent-n'
    'В': 'accent-v'
    'Ф': 'accent-f'
    'О': 'accent-o'
    'З': 'accent-z'
    'Г': 'accent-g'
    'П': 'accent-p'
    'Х': 'accent-h'
    'Р': 'accent-r'
    'И': 'accent-i'
    'С': 'accent-s'
    'А': 'accent-a'
    'Й': 'accent-i2'
    'Ш': 'accent-sh'
    'Э': 'accent-a2'
    'Ы': 'accent-i3'
    'Щ': 'accent-sh2'

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

  each: (str, keepSingle=-1, cb)->
    i = 0
    while i < str.length
      if i < str.length - 1
        if i isnt keepSingle and i+1 isnt keepSingle and @isSymbol(str.substr(i, 2))
          cb(str.substr(i, 2), i)
          i++
        else
          cb(str[i], i)
      else
        cb(str[i], i)

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
    @each text, -1, (symbol)=>
      symbolData = @getSymbolData(symbol, height)
      sum += symbolData.width

    # Add one more space as each word is spaced
    sum += @getSymbolData(' ', height).width

    return sum

  preSplitText: (text)->
    inputArea = @totalWidth * @totalHeight
    messageArea = @computeWidth(text.replace('\n', ' '), @maxHeight) * @maxHeight

    # Get ratio between available area and text area at max height
    areaRatio = inputArea / messageArea

    # Get max possible height
    maxHeight = Math.min(@maxHeight, @maxHeight * areaRatio)
    maxWidth = @totalWidth

    rows = []
    lines = text.split('\n')

    # Split each line in text rows that would fit given max height
    for line in lines
      # Check if line fits in row entirely
      if @computeWidth(line, maxHeight) <= maxWidth
        rows.push line
      else
        # Split by spaces and fit as many words per line as possible
        words = line.split(' ')
        rowWidth = 0
        prevIndex = 0
        currIndex = 0
        while currIndex < words.length
          if @computeWidth(words.slice(prevIndex, currIndex + 1).join(' '), maxHeight) > maxWidth
            # It is just one word and it is too big
            if prevIndex is currIndex
              rows.push(words[prevIndex])
              prevIndex += 1
            else
              rows.push(words.slice(prevIndex, currIndex).join(' '))
              prevIndex = currIndex

          currIndex += 1

        if prevIndex < currIndex
          rows.push(words.slice(prevIndex, currIndex).join(' '))

    newText = rows.join('\n').trim()

    return newText

  computeLineHeight: (text)->
    text = @preSplitText text

    # Compute min line height based on widest line
    preliminaryHeight = Infinity
    lines = text.split('\n')

    for line in lines
      lineWidth = @computeWidth line, @maxHeight # Compute character width if its height is 100
      lineHeight = (@maxHeight * (@totalWidth / lineWidth))
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

  writeText: (text=null, carretIndex=-1)->
    # Cache last text
    if text?
      text = text.substr(0, 200)
      @lastText = @preSplitText text
    # If no text, get from cache
    else if @lastText?
      text = @lastText

    # If no text then render default text
    if not text
      text = PRELOADED_MESSAGE || PRELOADED_MESSAGE_BACKUP

    # Move from 1 indexing to 0 indexing
    carretIndex -= 1

    text = cleanUpSpecialChars(text)
    text = unescape(text)
    lineHeightRaw = @computeLineHeight(text)
    lineHeight = Math.floor lineHeightRaw
    spriteWidth = @spriteWidth()
    maxCharacterWidth = Math.round @maxCharacterWidthByHeight(lineHeight)
    spaceHalfWidth = Math.floor(@getSymbolData(' ', lineHeight).width / 2)

    spaceFactory = (additionalClass)->
      "<span class='space'><strong class='#{additionalClass}' style='height: #{lineHeight}px;'></strong></span>"

    newText = ''

    if carretIndex is -1 and @state is 'WRITE'
      newText += spaceFactory('with-carret')

    newText += "<span style='padding: 0 #{spaceHalfWidth}px;'>" # First word
    @each text, carretIndex, (symbol, index)=>
      symbolData = @getSymbolData(symbol, lineHeight)
      symbolOffset = symbolData.index * 240 * maxCharacterWidth / spriteWidth
      additionalClass = ''

      if index is carretIndex and @state is 'WRITE'
        additionalClass = 'with-carret'

      if symbolData.symbol is ' '
        newText += "</span>#{spaceFactory(additionalClass)}<span style='padding: 0 #{spaceHalfWidth}px;'>"
      else if symbolData.symbol is '\n'
        newText += "</span><br>#{spaceFactory(additionalClass)}<span style='padding: 0 #{spaceHalfWidth}px;'>"
      else
        newText += "<strong class='letter #{additionalClass}' data-index='#{index}'><i style='width: #{Math.floor symbolData.width}px; height: #{lineHeight}px;'><img style='width:#{maxCharacterWidth}px;margin-top: -#{symbolOffset}px' src='#{URI_ROOT}public/fonts/#{@fontGroup}/font-sprite.jpg#{version}'></i></strong>"
    newText += "</span>" # Last tag

    @$text.find('span, br').remove()
    @$text.prepend(newText)

    @firstRender = false

  listenMessage: ->
    $('.message').on 'click', (ev)=>
      return false if @state isnt 'WRITE'

      $target = $(ev.target)
      $textarea = $('#textarea')

      if $target.closest('[data-index]').length
        index = $target.closest('[data-index]').data('index') + 1
        index = Math.min(index, $textarea.val().length)
      else
        index = $textarea.val().length

      $textarea.focus()
      $textarea.get(0).selectionStart = index
      $textarea.get(0).selectionEnd = index
      @writeText $textarea.val(), index
      return true

  listenTextarea: ->
    $message = $('#textarea')

    $(window).on 'click keyup', (ev)=>
      return true if @state isnt 'WRITE'
      return true if $(ev.target).closest('.message').length

      if not $message.is(':focus')
        @writeText $message.val(), -1

      return true

    $message.on 'focus keyup paste cut', (ev)=>
      return true if @state isnt 'WRITE'

      @writeText $message.val(), (if $message.get(0).selectionEnd? then $message.get(0).selectionEnd else $message.val().length)
      return true

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

  setState: (state)->
    if state in ['READ', 'WRITE'] and state isnt @state
      @state = state

      if @state is 'READ'
        1
      else if @state is 'WRITE'
        2

  start: ->
    @$text = $('#message')
    @state = window.MODE || 'WRITE'
    @firstRender = true
    @curtainOpened = false

    @fontGroup = "font#{PRELOADED_FONT}"
    @minHeight = 34
    @maxHeight = 120
    @computeMessageBoxSizes()

    $('#textarea').focus()
    @writeText()
    @listenMessage()
    @listenTextarea()
    @listenSelect()
    @listenResize()

###
# External helpers
###

listenForFontChange = (controller)->
  $wrappers = $('.content-wrapper')

  $('body').on 'click', '[data-action="prev-font"]', (ev)=>
    ev.preventDefault()
    currentFont = +controller.fontGroup[controller.fontGroup.length - 1]
    if currentFont is window.FONT_FIRST
      newFontIndex = window.FONT_LAST
    else
      newFontIndex = currentFont - 1

    newFont = "font#{newFontIndex}"

    $wrappers.filter("[data-type='#{newFont}']").addClass('active')
    $('.action-content-inner').animate {left: "-#{(newFontIndex - window.FONT_FIRST) * 100}%"}, ->
      $wrappers.not("[data-type='#{newFont}']").removeClass('active')
    controller.fontGroup = newFont
    controller.writeText()

  $('body').on 'click', '[data-action="next-font"]', (ev)=>
    ev.preventDefault()
    currentFont = +controller.fontGroup[controller.fontGroup.length - 1]
    if currentFont is window.FONT_LAST
      newFontIndex = window.FONT_FIRST
    else
      newFontIndex = currentFont + 1

    newFont = "font#{newFontIndex}"

    $wrappers.filter("[data-type='#{newFont}']").addClass('active')
    $('.action-content-inner').animate {left: "-#{(newFontIndex - window.FONT_FIRST) * 100}%"}, ->
      $wrappers.not("[data-type='#{newFont}']").removeClass('active')
    controller.fontGroup = newFont
    controller.writeText()

listenForFromToChange = (controller)->
  $createFrom = $('#create-from') # input
  $createTo = $('#create-to') # input
  $fromToInputs = $('.edit-block input')
  $textFrom = $('.text-from')
  $textTo = $('.text-to')

  $fromToInputs.on 'input paste keyup cut change focusout', ->
    $this = $(this)
    $this[if $this.val() then 'addClass' else 'removeClass']('has-content')

    $textFrom[if $createFrom.val() then 'show' else 'hide']().find('strong').text $createFrom.val()
    $textTo[if $createTo.val() then 'show' else 'hide']().find('strong').text $createTo.val()

  # Trigger change to update classes
  $fromToInputs.trigger('change')

listenForActionButtons = (controller)->
  $actionCopy = $('[data-action="copy"]')

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
        controller.setState 'READ'
        # Hide slide arrows
        $('.message-wrapper .action').hide()

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
    controller.setState 'WRITE'
    $('.footer-inner').animate {left: '-100%'}, ->
      history?.pushState?({}, document.title, URI_ROOT)
      $('#create-from').val('').trigger('change')
      $('#create-to').val('').trigger('change')
      $('#textarea').val($('#textarea').val() || PRELOADED_MESSAGE || '').trigger('change')
      $('#message').click()
      # Show slide arrows
      $('.message-wrapper .action').show()
      # Check if it is first time
      checkForCurtain(controller)

  $('body').on 'click', '[data-action="help"]', (ev)=>
    ev.preventDefault()
    $('body').addClass('with-overlay')

  $('body').on 'click', '[data-action="close-help"]', (ev)=>
    ev.preventDefault()
    $('body').removeClass('with-overlay')
    $('#textarea').focus()

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
    target = $(this).data('target')

    winWidth = 520
    winHeight = 510
    winTop = ($(window).height() / 2) - (winHeight / 2)
    winLeft = ($(window).width() / 2) - (winWidth / 2)

    title = 'Mesaje Dulci'
    # title = ''
    # descr = 'Alege-ți zahărul brun preferat și scrie un mesaj dulce celor dragi!'
    descr = ''
    url = URI_ROOT + 'mesaj/' + MESSAGE_ID
    # image = URI_ROOT + 'public/img/fb-cover.jpg'
    image = ''

    if target is 'fb'
      if $(window).width() > 720
        window.open('http://www.facebook.com/sharer.php?s=100&p[title]=' + title + '&p[summary]=' + descr + '&p[url]=' + url, 'sharer', 'top=' + winTop + ',left=' + winLeft + ',toolbar=0,status=0,width=' + winWidth + ',height=' + winHeight)
      else
        window.open('http://m.facebook.com/sharer.php?u=' + url, 'sharer', 'top=' + winTop + ',left=' + winLeft + ',toolbar=0,status=0,width=' + winWidth + ',height=' + winHeight)

    else if target is 'ok'
      window.open("http://www.odnoklassniki.ru/dk?st.cmd=addShare&st._surl=#{url}&title=#{title}")

checkForCurtain = (controller)->
  if controller.state is 'WRITE' and not controller.curtainOpened
    # Show help view
    $('body').addClass('with-overlay')

    controller.curtainOpened = true

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
      checkForCurtain controller

    # Preload other fonts
    fontSprites = []
    for i in [1..7]
      fontSprites.push "#{URI_ROOT}public/fonts/font#{i}/font-sprite.jpg#{version}"
    $.preload fontSprites, ->
      # console.log 'all fonts preloaded'
