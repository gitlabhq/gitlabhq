/*
 * this is a modified version of https://github.com/peek/peek/blob/master/app/assets/javascripts/peek.js
 *
 * - Removed the dependency on jquery.tipsy
 * - Removed the initializeTipsy and toggleBar functions
 * - Customized updatePerformanceBar to handle SQL query and Gitaly call lists
 * - Changed /peek/results to /-/peek/results
 * - Removed the keypress, pjax:end, page:change, and turbolinks:load handlers
 */
(function($) {
  var fetchRequestResults, getRequestId, peekEnabled, updatePerformanceBar, createTable, createTableRow;
  getRequestId = function() {
    return $('#peek').data('requestId');
  };
  peekEnabled = function() {
    return $('#peek').length;
  };
  updatePerformanceBar = function(results) {
    Object.keys(results.data).forEach(function(key) {
      Object.keys(results.data[key]).forEach(function(label) {
        var data = results.data[key][label];
        var table = createTable(key, label, data);
        var target = $('[data-defer-to="' + key + '-' + label + '"]');

        if (table) {
          target.html(table);
        } else {
          target.text(data);
        }
      });
    });
    return $(document).trigger('peek:render', [getRequestId(), results]);
  };
  createTable = function(key, label, data) {
    if (label !== 'queries' && label !== 'details') {
      return;
    }

    var table = document.createElement('table');

    for (var i = 0; i < data.length; i += 1) {
      table.appendChild(createTableRow(data[i]));
    }

    table.className = 'table';

    return table;
  };
  createTableRow = function(row) {
    var tr = document.createElement('tr');
    var durationTd = document.createElement('td');
    var strong = document.createElement('strong');

    strong.append(row['duration'] + 'ms');
    durationTd.appendChild(strong);
    tr.appendChild(durationTd);

    ['sql', 'feature', 'enabled', 'request'].forEach(function(key) {
      if (!row[key]) { return; }

      var td = document.createElement('td');

      td.appendChild(document.createTextNode(row[key]));
      tr.appendChild(td);
    });

    return tr;
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
  $(document).on('peek:update', fetchRequestResults);
  return $(function() {
    if (peekEnabled()) {
      return $(this).trigger('peek:update');
    }
  });
})(jQuery);
