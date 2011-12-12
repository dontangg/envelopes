
@hideModal = ->
  $('#overlay').hide()
  $('#modal').hide()

@showModal = (options) ->
  defaults =
    width: 400
  
  options = $.extend(defaults, options)
  
  overlay = $('#overlay')
  overlay = $("<div id='overlay'></div>") unless overlay.length > 0
  overlay.appendTo(document.body).css
    width: $(document).width()
    height: $(document).height()
    opacity: 0.6
  
  modal = $('#modal').removeClass()
  modal = $("<section id='modal'></section>") unless modal.length > 0
  modal.addClass(options['className']) if options['className']
  modal.html $(options['content']).html()

  modal.appendTo(document.body).css
    top: 100
    width: options['width']
    marginLeft: - options['width'] / 2
  
  input = modal.find 'input:visible, select:visible'
  input[0].focus() if input.length > 0

$ ->
  $('.flash').each (index, item) ->
    $(item).delay(4000).fadeOut()
