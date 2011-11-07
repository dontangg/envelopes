
$ ->
  $('.flash').each (index, item) ->
    $(item).delay(3000).animate top: -$(item).outerHeight()
