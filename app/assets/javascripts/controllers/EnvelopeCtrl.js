(function() {

var app = angular.module('envelopes');

app.factory('envelopeCtrlPreloader', ['$route', '$rootScope', 'transactionService', function($route, $rootScope, transactionService) {
  return {
    load: function() {
      var envelopeId = $route.current.params.envelopeId;

      if ($rootScope.showTransfers === undefined) {
        $rootScope.showTransfers = false;
      }
      if (!$rootScope.startDate) {
        // TODO: register constants with Angular for these formats
        $rootScope.startDate = moment().subtract(1, 'months').format('YYYY-MM-DD');
      }
      if (!$rootScope.endDate) {
        $rootScope.endDate = moment().format('YYYY-MM-DD');
      }

      return transactionService.find({
        envelopeId: envelopeId,
        showTransfers: $rootScope.showTransfers,
        startDate: $rootScope.startDate,
        endDate: $rootScope.endDate
      });
    }
  };
}]);

app.controller('EnvelopeCtrl', [
    '$scope', '$routeParams', '$rootScope', 'envelopeCtrlPreloader', 'envelopeService', 'data', function($scope, $routeParams, $rootScope, envelopeCtrlPreloader, envelopeService, data) {
      envelopeService.find($routeParams.envelopeId).then(function(envelope) {
        var parentId1 = envelope.parent_envelope_id;
        if (parentId1) {
          envelopeService.find(parentId1).then(function(parentEnvelope1) {
            var parentId2 = parentEnvelope1.parent_envelope_id;
            if (parentId2) {
              envelopeService.find(parentId2).then(function(parentEnvelope2) {
                $scope.fullParentName = parentEnvelope2.name + ": " + parentEnvelope1.name;
              });
            } else {
              $scope.fullParentName = parentEnvelope1.name;
            }
          });
        }

        $scope.envelope = envelope;
        $scope.transactions = data;

        var loadTransactions = function() {
          $scope.txnsLoading = true;
          return envelopeCtrlPreloader.load()
            .then(function(data) {
              $scope.transactions = data;
            })
            .finally(function() {
              $scope.txnsLoading = false;
            });
        };

        $scope.toggleTransfers = function() {
          $rootScope.showTransfers = !$rootScope.showTransfers;
          loadTransactions();
        };

        $scope.applyDates = function(startDate, endDate) {
          $rootScope.startDate = startDate;
          $rootScope.endDate = endDate;
          loadTransactions();
        };
      });
    }
]);

})();
