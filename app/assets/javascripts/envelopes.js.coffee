# Place all the behaviors and hooks related to the matching controller here.

setCurrentDateRange = ->
  startDate = $('#date_range_picker .start').datepicker('getDate')
  endDate = $('#date_range_picker .end').datepicker('getDate')
  $('#date_range_picker .start').datepicker("option", "maxDate", endDate)
  $('#date_range_picker .end').datepicker("option", "minDate", startDate)
  
  startDateText = $.datepicker.formatDate 'M d, yy', startDate
  endDateText = $.datepicker.formatDate 'M d, yy', endDate
  $('#date_range_picker .current').text(startDateText + " - " + endDateText)

cancelDatePicker = (event) ->
  if $('#date_range_picker .popup').is(':visible')
    $('#date_range_picker .popup').hide()
    $('#date_range_picker .start').datepicker('setDate', $('#date_range_picker .start').data('initialDate'))
    $('#date_range_picker .end').datepicker('setDate', $('#date_range_picker .end').data('initialDate'))
    setCurrentDateRange()

@setupDatePicker = ->
  $('#date_range_picker').click (event) ->
    event.stopPropagation()
    $(this).children('.popup').show()
  
  $('html').click cancelDatePicker
  $('#date_range_picker .actions a').click (event) ->
    event.preventDefault()
    event.stopPropagation()
    cancelDatePicker()
  
  $.datepicker.setDefaults
    onSelect: setCurrentDateRange
    dateFormat: 'yy-mm-dd'

  $('#date_range_picker .start').datepicker
    altField: '#start_date'
    defaultDate: $('#date_range_picker .start').data('initialDate')
  $('#date_range_picker .end').datepicker
    altField: '#end_date'
    defaultDate: $('#date_range_picker .end').data('initialDate')
  setCurrentDateRange()

$ ->
  $('#dashboard > ul').masonry
    itemSelector: '#dashboard > ul > li',
    columnWidth: 250,
    gutterWidth: 40,
    isAnimated: true
  
  if $('#date_range_picker').length > 0
    setupDatePicker()
  
  $('.amount input').on 'blur', ->
    $this = $(this)
    value = $this.val().replace /[^-.0-9]/g, ""
    value = parseFloat(value).toFixed 2
    value = value.replace /([.0-9]+)/g, "$$$1"
    $this.val value
  