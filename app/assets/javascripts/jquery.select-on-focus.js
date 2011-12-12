(function($) {

  var methods = {
    init: function(options) {
      
      return this.each(function() {
        
        var $this = $(this);
        
        var wasJustFocused = false;
        
        $this.on('focus.selectOnFocus', function() {
          if (this.select) {
            this.select();
            wasJustFocused = true;
          }
        });
        
        $this.on('mouseup.selectOnFocus', function(event) {
          if (wasJustFocused) {
            event.preventDefault();
            wasJustFocused = false;
          }
        });
        
      });
    },
    destroy: function() {
      return this.each(function() {

        var $this = $(this);

        $this.off('.selectOnFocus');

      });
    }
  };

  $.fn.selectOnFocus = function(method) {
    
    if (methods[method]) {
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === 'object' || !method) {
      return methods.init.apply(this, arguments);
    } else {
      $.error('Method ' +  method + ' does not exist on jQuery.selectOnFocus');
    }    
  
  };

})(jQuery);