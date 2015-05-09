(function() {

var app = angular.module('envelopes');
app.filter('envelopeUrl', function() {
  return function(envelope) {
    var name = envelope.name
      .toLowerCase()
      .replace(" ", "-")
      .replace(/[^a-zA-Z-]/, "");

    return "/envelopes/" + envelope.id + "-" + name;
  };
});

})();
