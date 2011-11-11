
$ ->
  $('.flash').each (index, item) ->
    $(item).delay(4000).animate top: -$(item).outerHeight()
