
@hideModal = ->
  $('#overlay').hide()
  $('#modal').hide()

@showModal = (options) ->
  defaults =
    width: 400
  
  options = $.extend(defaults, options)
  
  overlay = $('#overlay')
  overlay = $("<div id='overlay'></div>").appendTo(document.body) unless overlay.length > 0
  overlay.show().css
    width: $(document).width()
    height: $(document).height()
    opacity: 0.6
  
  modal = $('#modal').removeClass()
  modal = $("<section id='modal'></section>").appendTo(document.body) unless modal.length > 0
  modal.addClass(options['className']) if options['className']
  modal
    .html($(options['content']).html())
    .show()
    .css
      top: 100
      width: options['width']
      marginLeft: - options['width'] / 2
  
  input = modal.find 'input:visible, select:visible'
  input[0].focus() if input.length > 0

@autosave = (parentSelector, eventName, childSelector, url) ->
  changedCallback = (event) ->
    $this = $(this)
    if ($this.val() == $this.data('saved-value'))
      $this.removeClass 'invalid'
    else
      nameParts = $this.attr('name').split(/[\[\]]+/)
      [modelName, id, attributeName] = nameParts
      
      ajaxData = {}
      ajaxData[modelName + '[' + attributeName + ']'] = $this.val()

      $(parentSelector).find('.autosave-status').text 'Saving...'

      $.ajax
        type: 'PUT'
        url: url.replace(/{id}/, id)
        data: ajaxData
      .done ->
        $this.data('saved-value', ajaxData[modelName + '[' + attributeName + ']'])
        $this.removeClass 'invalid'

        now = new Date()
        hour = now.getHours()
        if hour > 12
          hour -= 12
          amPm = 'pm'
        else
          amPm = 'am'
        minute = now.getMinutes()
        minute = "0" + minute if minute < 10
        second = now.getSeconds()
        second = "0" + second if second < 10

        $(parentSelector).find('.autosave-status').text 'Saved at ' + hour + ':' + minute + ':' + second + amPm
      .fail (jqXHR, textStatus, next, next2) ->
        try
          errors = $.parseJSON(jqXHR.responseText)
          errorMessage = "The " + modelName + " wasn't saved!<ul>"
          for errorField of errors
            errorMessage += "<li>" + errorField + " " + errors[errorField].join(' and ') + "</li>"
          errorMessage += "</ul>"
        catch ex
          errorMessage = jqXHR.responseText
        
        $this.addClass 'invalid'

        showAlert errorMessage

  $(parentSelector).on eventName, childSelector, changedCallback

@showAlert = (alertMessage) ->
  $("<div class='flash alert'><div>" + alertMessage + "</div></div>")
    .insertAfter('#header_nav')
    .delay(4000)
    .fadeOut ->
      $(this).remove()

$ ->
  $('.flash').each (index, item) ->
    $(item)
      .delay(4000)
      .fadeOut ->
        $(this).remove()
