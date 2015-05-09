(function() {

var app = angular.module('envelopes');
app.directive('dateRangeControl', ['storageDateFormat', function(storageDateFormat) {
  return {
    templateUrl: '/assets/partials/date_range.html',
    scope: {
      start: '@',
      end: '@',
      apply: '&'
    },
    link: function(scope, element, attrs) {
      var visualDateFormat = 'll';
      var supportedDateFormats = ['YYYY-MM-DD', 'YYYY-M-D', 'MMMM D, YYYY', 'M/D/YYYY', 'M-D-YYYY'];

      scope.getParams = function() {
        var startM = moment(scope.start, supportedDateFormats);
        var endM = moment(scope.end, supportedDateFormats);
        return {
          startDate: startM.format(storageDateFormat),
          endDate: endM.format(storageDateFormat)
        };
      };

      // observe attribute changes (not isolate scope changes)
      var appliedStart;
      var appliedEnd;
      attrs.$observe('start', function(newStart) {
        appliedStart = newStart;
        scope.start = moment(newStart, storageDateFormat).format(visualDateFormat);
        scope.hasChanged = false;
        return scope.hasError = false;
      });
      attrs.$observe('end', function(newEnd) {
        appliedEnd = newEnd;
        scope.end = moment(newEnd, storageDateFormat).format(visualDateFormat);
        scope.hasChanged = false;
        return scope.hasError = false;
      });

      var validate = function() {
        var bothValid = true;
        
        var dateArray = [scope.start, scope.end];
        for (var i = 0; i < dateArray.length; i++) {
          if (dateArray[i] === 'today') {
            dateArray[i] = moment().format(visualDateFormat);
          }
          var m = moment(dateArray[i], supportedDateFormats);
          if (!m.isValid()) {
            bothValid = false;
          }
        }

        scope.hasError = !bothValid;

        if (bothValid) {
          var start = moment(dateArray[0], supportedDateFormats).format(storageDateFormat);
          var end = moment(dateArray[1], supportedDateFormats).format(storageDateFormat);
          scope.hasChanged = start !== appliedStart || end !== appliedEnd;
        }
      };

      scope.format = function(varName) {
        var m = scope[varName] === 'today' ? moment() : moment(scope[varName], supportedDateFormats);

        if (m.isValid()) {
          scope[varName] = m.format(visualDateFormat);
        }
      };
      
      scope.$watch('start', function() {
        validate();
      });
      scope.$watch('end', function() {
        validate();
      });
    }
  };
}]);

})();
