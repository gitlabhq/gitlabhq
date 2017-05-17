var requestId;

requestId = null;

(function($) {
  var fetchRequestResults, getRequestId, initializeTipsy, peekEnabled, toggleBar, updatePerformanceBar;
  getRequestId = function() {
    if (requestId != null) {
      return requestId;
    } else {
      return $('#peek').data('request-id');
    }
  };
  peekEnabled = function() {
    return $('#peek').length;
  };
  updatePerformanceBar = function(results) {
    var key, label;
    for (key in results.data) {
      for (label in results.data[key]) {
        $("[data-defer-to=" + key + "-" + label + "]").text(results.data[key][label]);
      }
    }
    return $(document).trigger('peek:render', [getRequestId(), results]);
  };
  initializeTipsy = function() {
    return $('#peek .peek-tooltip, #peek .tooltip').each(function() {
      var el, gravity;
      el = $(this);
      gravity = el.hasClass('rightwards') || el.hasClass('leftwards') ? $.fn.tipsy.autoWE : $.fn.tipsy.autoNS;
      return el.tipsy({
        gravity: gravity
      });
    });
  };
  toggleBar = function(event) {
    var wrapper;
    if ($(event.target).is(':input')) {
      return;
    }
    if (event.which === 96 && !event.metaKey) {
      wrapper = $('#peek');
      if (wrapper.hasClass('disabled')) {
        wrapper.removeClass('disabled');
        return document.cookie = "peek=true; path=/";
      } else {
        wrapper.addClass('disabled');
        return document.cookie = "peek=false; path=/";
      }
    }
  };
  fetchRequestResults = function() {
    return $.ajax('/peek/results', {
      data: {
        request_id: getRequestId()
      },
      success: function(data, textStatus, xhr) {
        return updatePerformanceBar(data);
      },
      error: function(xhr, textStatus, error) {}
    });
  };
  $(document).on('keypress', toggleBar);
  $(document).on('peek:update', initializeTipsy);
  $(document).on('peek:update', fetchRequestResults);
  $(document).on('pjax:end', function(event, xhr, options) {
    if (xhr != null) {
      requestId = xhr.getResponseHeader('X-Request-Id');
    }
    if (peekEnabled()) {
      return $(this).trigger('peek:update');
    }
  });
  $(document).on('page:change turbolinks:load', function() {
    if (peekEnabled()) {
      return $(this).trigger('peek:update');
    }
  });
  return $(function() {
    if (peekEnabled()) {
      return $(this).trigger('peek:update');
    }
  });
})(jQuery);
