(function() {

var app = angular.module('envelopes');
app.controller('GrowlCtrl', ['$scope', 'notificationService', function($scope, notificationService) {
  return $scope.notifications = notificationService.get();
}]);

})();
