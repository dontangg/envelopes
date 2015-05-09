(function() {

var app = angular.module('envelopes');
app.factory('transactionService', ['$http', 'notificationService', function($http, notificationService) {
  return {
    find: function(options) {
      var envelopeId = options.envelopeId;

      options = {
        params: {
          show_transfers: options.showTransfers,
          start_date: options.startDate,
          end_date: options.endDate
        }
      };

      return $http.get("/envelopes/" + envelopeId + "/transactions.json", options)
        .error(function() {
          notificationService.add({
            type: 'danger',
            title: 'Oh snap!',
            message: 'There was a problem getting transactions.'
          });
        })
        .then(function(response) {
          return response.data;
        });
    }
  };
}]);

})();
