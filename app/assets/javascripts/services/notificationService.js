(function() {

var app = angular.module('envelopes');
app.factory('notificationService', function() {
  var notifications = [];

  return {
    get: function() {
      return notifications;
    },
    remove: function(notification) {
      var index = notifications.indexOf(notification);
      if (index !== -1) {
        notifications.splice(index, 1);
      }
    },
    add: function(notification) {
      // Add reasonable defaults
      if (notification.isDismissible !== false) {
        notification.isDismissible = true;
      }
      if (notification.useTimer !== false) {
        notification.useTimer = true;
      }

      notifications.push(notification);
    }
  };
});

})();
