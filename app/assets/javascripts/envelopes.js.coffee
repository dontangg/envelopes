# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

setCurrentDateRange = ->
  startDate = $('#date-range-picker .start').datepicker('getDate')
  endDate = $('#date-range-picker .end').datepicker('getDate')
  $('#date-range-picker .start').datepicker("option", "maxDate", endDate)
  $('#date-range-picker .end').datepicker("option", "minDate", startDate)
  
  startDateText = $.datepicker.formatDate 'M d, yy', startDate
  endDateText = $.datepicker.formatDate 'M d, yy', endDate
  $('#date-range-picker .current').text(startDateText + " - " + endDateText)

$ ->
  $('#dashboard > ul').masonry
    itemSelector: '#dashboard > ul > li',
    columnWidth: 250,
    gutterWidth: 40,
    isAnimated: true
    
  $('#date-range-picker').click (event) ->
    event.stopPropagation()
    $(this).children('.popup').show()
  
  $('body').click (event) ->
    $('#date-range-picker .popup').hide()
  
  $('#date-range-picker .start').datepicker
    onSelect: setCurrentDateRange
  $('#date-range-picker .end').datepicker
    onSelect: setCurrentDateRange
