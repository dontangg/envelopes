(function() {

var app = angular.module('envelopes');
app.factory('envelopeService', ['$http', '$q', 'notificationService', function($http, $q, notificationService) {
  var envelopesPromise = null;

  var getEnvelopes = function() {
    if (envelopesPromise) {
      return envelopesPromise;
    }
    return envelopesPromise = $http.get('/envelopes.json').error(function() {
      return notificationService.add({
        type: 'danger',
        title: 'Oh snap!',
        message: 'There was a problem getting envelopes.'
      });
    }).then(function(response) {
      var data = response.data;
      var organized_envelopes = data[""];
      var stack = data[""].slice();
      while (stack.length) {
        var env = stack.pop();
        if (data[env.id]) {
          stack = stack.concat(data[env.id]);
          env.children = data[env.id];
        }
      }
      return organized_envelopes;
    });
  };

  var findById = function(id) {
    return getEnvelopes().then(function(envelopes) {
      return $q(function(resolve, reject) {
        id = parseInt(id);
        var stack = envelopes.slice();
        while (stack.length) {
          var envelope = stack.pop();
          if (envelope.id === id) {
            resolve(envelope);
            return;
          }
          if (envelope.children) {
            stack = stack.concat(envelope.children);
          }
        }
        reject("Unable to find envelope id: " + id);
      });
    });
  };

  return {
    all: getEnvelopes,
    find: findById
  };

}]);

})();
