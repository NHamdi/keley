###*
*  Ajax Autocomplete for jQuery, version %version%
*  (c) 2015 Tomas Kirda
*
*  Ajax Autocomplete for jQuery is freely distributable under the terms of an MIT-style license.
*  For details, see the web site: https://github.com/devbridge/jQuery-Autocomplete
###

###jslint  browser: true, white: true, plusplus: true, vars: true ###

###global define, window, document, jQuery, exports, require ###

# Expose plugin as an AMD module if AMD loader is present:
((factory) ->
  'use strict'
  if typeof define == 'function' and define.amd
    # AMD. Register as an anonymous module.
    define [ 'jquery' ], factory
  else if typeof exports == 'object' and typeof require == 'function'
    # Browserify
    factory require('jquery')
  else
    # Browser globals
    factory jQuery
  return
) ($) ->

  Autocomplete = (el, options) ->

    noop = ->

    that = this
    defaults =
      ajaxSettings: {}
      autoSelectFirst: false
      appendTo: document.body
      serviceUrl: null
      lookup: null
      onSelect: null
      width: 'auto'
      minChars: 1
      maxHeight: 300
      deferRequestBy: 0
      params: {}
      formatResult: Autocomplete.formatResult
      delimiter: null
      zIndex: 9999
      type: 'GET'
      noCache: false
      onSearchStart: noop
      onSearchComplete: noop
      onSearchError: noop
      preserveInput: false
      containerClass: 'autocomplete-suggestions'
      tabDisabled: false
      dataType: 'text'
      currentRequest: null
      triggerSelectOnValidInput: true
      preventBadQueries: true
      lookupFilter: (suggestion, originalQuery, queryLowerCase) ->
        suggestion.value.toLowerCase().indexOf(queryLowerCase) != -1
      paramName: 'query'
      transformResult: (response) ->
        if typeof response == 'string' then $.parseJSON(response) else response
      showNoSuggestionNotice: false
      noSuggestionNotice: 'No results'
      orientation: 'bottom'
      forceFixPosition: false
    # Shared variables:
    that.element = el
    that.el = $(el)
    that.suggestions = []
    that.badQueries = []
    that.selectedIndex = -1
    that.currentValue = that.element.value
    that.intervalId = 0
    that.cachedResponse = {}
    that.onChangeInterval = null
    that.onChange = null
    that.isLocal = false
    that.suggestionsContainer = null
    that.noSuggestionsContainer = null
    that.options = $.extend({}, defaults, options)
    that.classes =
      selected: 'autocomplete-selected'
      suggestion: 'autocomplete-suggestion'
    that.hint = null
    that.hintValue = ''
    that.selection = null
    # Initialize and set options:
    that.initialize()
    that.setOptions options
    return

  'use strict'
  utils = do ->
    {
    escapeRegExChars: (value) ->
      value.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&'
    createNode: (containerClass) ->
      div = document.createElement('div')
      div.className = containerClass
      div.style.position = 'absolute'
      div.style.display = 'none'
      div

    }
  keys =
    ESC: 27
    TAB: 9
    RETURN: 13
    LEFT: 37
    UP: 38
    RIGHT: 39
    DOWN: 40
  Autocomplete.utils = utils
  $.Autocomplete = Autocomplete

  Autocomplete.formatResult = (suggestion, currentValue) ->
    pattern = '(' + utils.escapeRegExChars(currentValue) + ')'
    suggestion.value.replace(new RegExp(pattern, 'gi'), '<strong>$1</strong>').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace /&lt;(\/?strong)&gt;/g, '<$1>'

  Autocomplete.prototype =
    killerFn: null
    initialize: ->
      that = this
      suggestionSelector = '.' + that.classes.suggestion
      selected = that.classes.selected
      options = that.options
      container = undefined
      # Remove autocomplete attribute to prevent native suggestions:
      that.element.setAttribute 'autocomplete', 'off'

      that.killerFn = (e) ->
        if $(e.target).closest('.' + that.options.containerClass).length == 0
          that.killSuggestions()
          that.disableKillerFn()
        return

      # html() deals with many types: htmlString or Element or Array or jQuery
      that.noSuggestionsContainer = $('<div class="autocomplete-no-suggestion"></div>').html(@options.noSuggestionNotice).get(0)
      that.suggestionsContainer = Autocomplete.utils.createNode(options.containerClass)
      container = $(that.suggestionsContainer)
      container.appendTo options.appendTo
      # Only set width if it was provided:
      if options.width != 'auto'
        container.width options.width
      # Listen for mouse over event on suggestions list:
      container.on 'mouseover.autocomplete', suggestionSelector, ->
        that.activate $(this).data('index')
        return
      # Deselect active element when mouse leaves suggestions container:
      container.on 'mouseout.autocomplete', ->
        that.selectedIndex = -1
        container.children('.' + selected).removeClass selected
        return
      # Listen for click event on suggestions list:
      container.on 'click.autocomplete', suggestionSelector, ->
        that.select $(this).data('index')
        return

      that.fixPositionCapture = ->
        if that.visible
          that.fixPosition()
        return

      $(window).on 'resize.autocomplete', that.fixPositionCapture
      that.el.on 'keydown.autocomplete', (e) ->
        that.onKeyPress e
        return
      that.el.on 'keyup.autocomplete', (e) ->
        that.onKeyUp e
        return
      that.el.on 'blur.autocomplete', ->
        that.onBlur()
        return
      that.el.on 'focus.autocomplete', ->
        that.onFocus()
        return
      that.el.on 'change.autocomplete', (e) ->
        that.onKeyUp e
        return
      that.el.on 'input.autocomplete', (e) ->
        that.onKeyUp e
        return
      return
    onFocus: ->
      that = this
      that.fixPosition()
      if that.options.minChars == 0 and that.el.val().length == 0
        that.onValueChange()
      return
    onBlur: ->
      @enableKillerFn()
      return
    abortAjax: ->
      that = this
      if that.currentRequest
        that.currentRequest.abort()
        that.currentRequest = null
      return
    setOptions: (suppliedOptions) ->
      that = this
      options = that.options
      $.extend options, suppliedOptions
      that.isLocal = $.isArray(options.lookup)
      if that.isLocal
        options.lookup = that.verifySuggestionsFormat(options.lookup)
      options.orientation = that.validateOrientation(options.orientation, 'bottom')
      # Adjust height, width and z-index:
      $(that.suggestionsContainer).css
        'max-height': options.maxHeight + 'px'
        'width': options.width + 'px'
        'z-index': options.zIndex
      return
    clearCache: ->
      @cachedResponse = {}
      @badQueries = []
      return
    clear: ->
      @clearCache()
      @currentValue = ''
      @suggestions = []
      return
    disable: ->
      that = this
      that.disabled = true
      clearInterval that.onChangeInterval
      that.abortAjax()
      return
    enable: ->
      @disabled = false
      return
    fixPosition: ->
      # Use only when container has already its content
      that = this
      $container = $(that.suggestionsContainer)
      containerParent = $container.parent().get(0)
      # Fix position automatically when appended to body.
      # In other cases force parameter must be given.
      if containerParent != document.body and !that.options.forceFixPosition
        return
      # Choose orientation
      orientation = that.options.orientation
      containerHeight = $container.outerHeight()
      height = that.el.outerHeight()
      offset = that.el.offset()
      styles =
        'top': offset.top
        'left': offset.left
      if orientation == 'auto'
        viewPortHeight = $(window).height()
        scrollTop = $(window).scrollTop()
        topOverflow = -scrollTop + offset.top - containerHeight
        bottomOverflow = scrollTop + viewPortHeight - (offset.top + height + containerHeight)
        orientation = if Math.max(topOverflow, bottomOverflow) == topOverflow then 'top' else 'bottom'
      if orientation == 'top'
        styles.top += -containerHeight
      else
        styles.top += height
      # If container is not positioned to body,
      # correct its position using offset parent offset
      if containerParent != document.body
        opacity = $container.css('opacity')
        parentOffsetDiff = undefined
        if !that.visible
          $container.css('opacity', 0).show()
        parentOffsetDiff = $container.offsetParent().offset()
        styles.top -= parentOffsetDiff.top
        styles.left -= parentOffsetDiff.left
        if !that.visible
          $container.css('opacity', opacity).hide()
      # -2px to account for suggestions border.
      if that.options.width == 'auto'
        styles.width = that.el.outerWidth() - 2 + 'px'
      $container.css styles
      return
    enableKillerFn: ->
      that = this
      $(document).on 'click.autocomplete', that.killerFn
      return
    disableKillerFn: ->
      that = this
      $(document).off 'click.autocomplete', that.killerFn
      return
    killSuggestions: ->
      that = this
      that.stopKillSuggestions()
      that.intervalId = window.setInterval((->
        if that.visible
          that.el.val that.currentValue
          that.hide()
        that.stopKillSuggestions()
        return
      ), 50)
      return
    stopKillSuggestions: ->
      window.clearInterval @intervalId
      return
    isCursorAtEnd: ->
      that = this
      valLength = that.el.val().length
      selectionStart = that.element.selectionStart
      range = undefined
      if typeof selectionStart == 'number'
        return selectionStart == valLength
      if document.selection
        range = document.selection.createRange()
        range.moveStart 'character', -valLength
        return valLength == range.text.length
      true
    onKeyPress: (e) ->
      that = this
      # If suggestions are hidden and user presses arrow down, display suggestions:
      if !that.disabled and !that.visible and e.which == keys.DOWN and that.currentValue
        that.suggest()
        return
      if that.disabled or !that.visible
        return
      switch e.which
        when keys.ESC
          that.el.val that.currentValue
          that.hide()
        when keys.RIGHT
          if that.hint and that.options.onHint and that.isCursorAtEnd()
            that.selectHint()
            break
          return
        when keys.TAB
          if that.hint and that.options.onHint
            that.selectHint()
            return
          if that.selectedIndex == -1
            that.hide()
            return
          that.select that.selectedIndex
          if that.options.tabDisabled == false
            return
        when keys.RETURN
          if that.selectedIndex == -1
            that.hide()
            return
          that.select that.selectedIndex
        when keys.UP
          that.moveUp()
        when keys.DOWN
          that.moveDown()
        else
          return
      # Cancel event if function did not return:
      e.stopImmediatePropagation()
      e.preventDefault()
      return
    onKeyUp: (e) ->
      that = this
      if that.disabled
        return
      switch e.which
        when keys.UP, keys.DOWN
          return
      clearInterval that.onChangeInterval
      if that.currentValue != that.el.val()
        that.findBestHint()
        if that.options.deferRequestBy > 0
          # Defer lookup in case when value changes very quickly:
          that.onChangeInterval = setInterval((->
            that.onValueChange()
            return
          ), that.options.deferRequestBy)
        else
          that.onValueChange()
      return
    onValueChange: ->
      that = this
      options = that.options
      value = that.el.val()
      query = that.getQuery(value)
      if that.selection and that.currentValue != query
        that.selection = null
        (options.onInvalidateSelection or $.noop).call that.element
      clearInterval that.onChangeInterval
      that.currentValue = value
      that.selectedIndex = -1
      # Check existing suggestion for the match before proceeding:
      if options.triggerSelectOnValidInput and that.isExactMatch(query)
        that.select 0
        return
      if query.length < options.minChars
        that.hide()
      else
        that.getSuggestions query
      return
    isExactMatch: (query) ->
      suggestions = @suggestions
      suggestions.length == 1 and suggestions[0].value.toLowerCase() == query.toLowerCase()
    getQuery: (value) ->
      delimiter = @options.delimiter
      parts = undefined
      if !delimiter
        return value
      parts = value.split(delimiter)
      $.trim parts[parts.length - 1]
    getSuggestionsLocal: (query) ->
      that = this
      options = that.options
      queryLowerCase = query.toLowerCase()
      filter = options.lookupFilter
      limit = parseInt(options.lookupLimit, 10)
      data = undefined
      data = suggestions: $.grep(options.lookup, (suggestion) ->
        filter suggestion, query, queryLowerCase
      )
      if limit and data.suggestions.length > limit
        data.suggestions = data.suggestions.slice(0, limit)
      data
    getSuggestions: (q) ->
      response = undefined
      that = this
      options = that.options
      serviceUrl = options.serviceUrl
      params = undefined
      cacheKey = undefined
      ajaxSettings = undefined
      options.params[options.paramName] = q
      params = if options.ignoreParams then null else options.params
      if options.onSearchStart.call(that.element, options.params) == false
        return
      if $.isFunction(options.lookup)
        options.lookup q, (data) ->
          that.suggestions = data.suggestions
          that.suggest()
          options.onSearchComplete.call that.element, q, data.suggestions
          return
        return
      if that.isLocal
        response = that.getSuggestionsLocal(q)
      else
        if $.isFunction(serviceUrl)
          serviceUrl = serviceUrl.call(that.element, q)
        cacheKey = serviceUrl + '?' + $.param(params or {})
        response = that.cachedResponse[cacheKey]
      if response and $.isArray(response.suggestions)
        that.suggestions = response.suggestions
        that.suggest()
        options.onSearchComplete.call that.element, q, response.suggestions
      else if !that.isBadQuery(q)
        that.abortAjax()
        ajaxSettings =
          url: serviceUrl
          data: params
          type: options.type
          dataType: options.dataType
        $.extend ajaxSettings, options.ajaxSettings
        that.currentRequest = $.ajax(ajaxSettings).done((data) ->
          result = undefined
          that.currentRequest = null
          result = options.transformResult(data, q)
          that.processResponse result, q, cacheKey
          options.onSearchComplete.call that.element, q, result.suggestions
          return
        ).fail((jqXHR, textStatus, errorThrown) ->
          options.onSearchError.call that.element, q, jqXHR, textStatus, errorThrown
          return
        )
      else
        options.onSearchComplete.call that.element, q, []
      return
    isBadQuery: (q) ->
      if !@options.preventBadQueries
        return false
      badQueries = @badQueries
      i = badQueries.length
      while i--
        if q.indexOf(badQueries[i]) == 0
          return true
      false
    hide: ->
      that = this
      container = $(that.suggestionsContainer)
      if $.isFunction(that.options.onHide) and that.visible
        that.options.onHide.call that.element, container
      that.visible = false
      that.selectedIndex = -1
      clearInterval that.onChangeInterval
      $(that.suggestionsContainer).hide()
      that.signalHint null
      return
    suggest: ->
      if @suggestions.length == 0
        if @options.showNoSuggestionNotice
          @noSuggestions()
        else
          @hide()
        return
      that = this
      options = that.options
      groupBy = options.groupBy
      formatResult = options.formatResult
      value = that.getQuery(that.currentValue)
      className = that.classes.suggestion
      classSelected = that.classes.selected
      container = $(that.suggestionsContainer)
      noSuggestionsContainer = $(that.noSuggestionsContainer)
      beforeRender = options.beforeRender
      html = ''
      category = undefined

      formatGroup = (suggestion, index) ->
        currentCategory = suggestion.data[groupBy]
        if category == currentCategory
          return ''
        category = currentCategory
        '<div class="autocomplete-group"><strong>' + category + '</strong></div>'

      if options.triggerSelectOnValidInput and that.isExactMatch(value)
        that.select 0
        return
      # Build suggestions inner HTML:
      $.each that.suggestions, (i, suggestion) ->
        if groupBy
          html += formatGroup(suggestion, value, i)
        html += '<div class="' + className + '" data-index="' + i + '">' + formatResult(suggestion, value) + '</div>'
        return
      @adjustContainerWidth()
      noSuggestionsContainer.detach()
      container.html html
      if $.isFunction(beforeRender)
        beforeRender.call that.element, container
      that.fixPosition()
      container.show()
      # Select first value by default:
      if options.autoSelectFirst
        that.selectedIndex = 0
        container.scrollTop 0
        container.children('.' + className).first().addClass classSelected
      that.visible = true
      that.findBestHint()
      return
    noSuggestions: ->
      that = this
      container = $(that.suggestionsContainer)
      noSuggestionsContainer = $(that.noSuggestionsContainer)
      @adjustContainerWidth()
      # Some explicit steps. Be careful here as it easy to get
      # noSuggestionsContainer removed from DOM if not detached properly.
      noSuggestionsContainer.detach()
      container.empty()
      # clean suggestions if any
      container.append noSuggestionsContainer
      that.fixPosition()
      container.show()
      that.visible = true
      return
    adjustContainerWidth: ->
      that = this
      options = that.options
      width = undefined
      container = $(that.suggestionsContainer)
      # If width is auto, adjust width before displaying suggestions,
      # because if instance was created before input had width, it will be zero.
      # Also it adjusts if input width has changed.
      # -2px to account for suggestions border.
      if options.width == 'auto'
        width = that.el.outerWidth() - 2
        container.width if width > 0 then width else 300
      return
    findBestHint: ->
      that = this
      value = that.el.val().toLowerCase()
      bestMatch = null
      if !value
        return
      $.each that.suggestions, (i, suggestion) ->
        foundMatch = suggestion.value.toLowerCase().indexOf(value) == 0
        if foundMatch
          bestMatch = suggestion
        !foundMatch
      that.signalHint bestMatch
      return
    signalHint: (suggestion) ->
      hintValue = ''
      that = this
      if suggestion
        hintValue = that.currentValue + suggestion.value.substr(that.currentValue.length)
      if that.hintValue != hintValue
        that.hintValue = hintValue
        that.hint = suggestion
        (@options.onHint or $.noop) hintValue
      return
    verifySuggestionsFormat: (suggestions) ->
      # If suggestions is string array, convert them to supported format:
      if suggestions.length and typeof suggestions[0] == 'string'
        return $.map(suggestions, (value) ->
          {
          value: value
          data: null
          }
        )
      suggestions
    validateOrientation: (orientation, fallback) ->
      orientation = $.trim(orientation or '').toLowerCase()
      if $.inArray(orientation, [
        'auto'
        'bottom'
        'top'
      ]) == -1
        orientation = fallback
      orientation
    processResponse: (result, originalQuery, cacheKey) ->
      that = this
      options = that.options
      result.suggestions = that.verifySuggestionsFormat(result.suggestions)
      # Cache results if cache is not disabled:
      if !options.noCache
        that.cachedResponse[cacheKey] = result
        if options.preventBadQueries and result.suggestions.length == 0
          that.badQueries.push originalQuery
      # Return if originalQuery is not matching current query:
      if originalQuery != that.getQuery(that.currentValue)
        return
      that.suggestions = result.suggestions
      that.suggest()
      return
    activate: (index) ->
      that = this
      activeItem = undefined
      selected = that.classes.selected
      container = $(that.suggestionsContainer)
      children = container.find('.' + that.classes.suggestion)
      container.find('.' + selected).removeClass selected
      that.selectedIndex = index
      if that.selectedIndex != -1 and children.length > that.selectedIndex
        activeItem = children.get(that.selectedIndex)
        $(activeItem).addClass selected
        return activeItem
      null
    selectHint: ->
      that = this
      i = $.inArray(that.hint, that.suggestions)
      that.select i
      return
    select: (i) ->
      that = this
      that.hide()
      that.onSelect i
      return
    moveUp: ->
      that = this
      if that.selectedIndex == -1
        return
      if that.selectedIndex == 0
        $(that.suggestionsContainer).children().first().removeClass that.classes.selected
        that.selectedIndex = -1
        that.el.val that.currentValue
        that.findBestHint()
        return
      that.adjustScroll that.selectedIndex - 1
      return
    moveDown: ->
      that = this
      if that.selectedIndex == that.suggestions.length - 1
        return
      that.adjustScroll that.selectedIndex + 1
      return
    adjustScroll: (index) ->
      that = this
      activeItem = that.activate(index)
      if !activeItem
        return
      offsetTop = undefined
      upperBound = undefined
      lowerBound = undefined
      heightDelta = $(activeItem).outerHeight()
      offsetTop = activeItem.offsetTop
      upperBound = $(that.suggestionsContainer).scrollTop()
      lowerBound = upperBound + that.options.maxHeight - heightDelta
      if offsetTop < upperBound
        $(that.suggestionsContainer).scrollTop offsetTop
      else if offsetTop > lowerBound
        $(that.suggestionsContainer).scrollTop offsetTop - (that.options.maxHeight) + heightDelta
      if !that.options.preserveInput
        that.el.val that.getValue(that.suggestions[index].value)
      that.signalHint null
      return
    onSelect: (index) ->
      that = this
      onSelectCallback = that.options.onSelect
      suggestion = that.suggestions[index]
      that.currentValue = that.getValue(suggestion.value)
      if that.currentValue != that.el.val() and !that.options.preserveInput
        that.el.val that.currentValue
      that.signalHint null
      that.suggestions = []
      that.selection = suggestion
      if $.isFunction(onSelectCallback)
        onSelectCallback.call that.element, suggestion
      return
    getValue: (value) ->
      that = this
      delimiter = that.options.delimiter
      currentValue = undefined
      parts = undefined
      if !delimiter
        return value
      currentValue = that.currentValue
      parts = currentValue.split(delimiter)
      if parts.length == 1
        return value
      currentValue.substr(0, currentValue.length - (parts[parts.length - 1].length)) + value
    dispose: ->
      that = this
      that.el.off('.autocomplete').removeData 'autocomplete'
      that.disableKillerFn()
      $(window).off 'resize.autocomplete', that.fixPositionCapture
      $(that.suggestionsContainer).remove()
      return
  # Create chainable jQuery plugin:
  $.fn.autocomplete =
    $.fn.devbridgeAutocomplete = (options, args) ->
      dataKey = 'autocomplete'
      # If function invoked without argument return
      # instance of the first matched element:
      if arguments.length == 0
        return @first().data(dataKey)
      @each ->
        inputElement = $(this)
        instance = inputElement.data(dataKey)
        if typeof options == 'string'
          if instance and typeof instance[options] == 'function'
            instance[options] args
        else
          # If instance already exists, destroy it:
          if instance and instance.dispose
            instance.dispose()
          instance = new Autocomplete(this, options)
          inputElement.data dataKey, instance
        return

  return
