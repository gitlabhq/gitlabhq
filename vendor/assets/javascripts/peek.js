(function($) {
  var fetchRequestResults, getRequestId, peekEnabled, toggleBar, updatePerformanceBar;
  getRequestId = function() {
    return $('#peek').data('request-id');
  };
  peekEnabled = function() {
    return $('#peek').length;
  };
  updatePerformanceBar = function(results) {
    var key, label, data, table, html, tr, duration_td, sql_td, strong;

    Object.keys(results.data).forEach(function(key) {
      Object.keys(results.data[key]).forEach(function(label) {
        data = results.data[key][label];

        if (label == 'queries') {
          table = document.createElement('table');

          for (var i = 0; i < data.length; i += 1) {
            tr = document.createElement('tr');
            duration_td = document.createElement('td');
            sql_td = document.createElement('td');
            strong = document.createElement('strong');

            strong.append(data[i]['duration'] + 'ms');
            duration_td.appendChild(strong);
            tr.appendChild(duration_td);

            sql_td.appendChild(document.createTextNode(data[i]['sql']));
            tr.appendChild(sql_td);

            table.appendChild(tr);
          }

          table.className = 'table';
          $("[data-defer-to=" + key + "-" + label + "]").html(table);
        } else {
          $("[data-defer-to=" + key + "-" + label + "]").text(results.data[key][label]);
        }
      });
    });
    return $(document).trigger('peek:render', [getRequestId(), results]);
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
    return $.ajax('/-/peek/results', {
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
  $(document).on('peek:update', fetchRequestResults);
  return $(function() {
    if (peekEnabled()) {
      return $(this).trigger('peek:update');
    }
  });
})(jQuery);
