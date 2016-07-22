
/*= provides tasklist:enabled */

/*= provides tasklist:disabled */

/*= provides tasklist:change */

/*= provides tasklist:changed */
var codeFencesPattern, complete, completePattern, disableTaskList, disableTaskLists, enableTaskList, enableTaskLists, escapePattern, incomplete, incompletePattern, itemPattern, itemsInParasPattern, updateTaskList, updateTaskListItem,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

incomplete = "[ ]";

complete = "[x]";

escapePattern = function(str) {
  return str.replace(/([\[\]])/g, "\\$1").replace(/\s/, "\\s").replace("x", "[xX]");
};

incompletePattern = RegExp("" + (escapePattern(incomplete)));

completePattern = RegExp("" + (escapePattern(complete)));

itemPattern = RegExp("^(?:\\s*(?:>\\s*)*(?:[-+*]|(?:\\d+\\.)))\\s*(" + (escapePattern(complete)) + "|" + (escapePattern(incomplete)) + ")\\s+(?!\\(.*?\\))(?=(?:\\[.*?\\]\\s*(?:\\[.*?\\]|\\(.*?\\))\\s*)*(?:[^\\[]|$))");

codeFencesPattern = /^`{3}(?:\s*\w+)?[\S\s].*[\S\s]^`{3}$/mg;

itemsInParasPattern = RegExp("^(" + (escapePattern(complete)) + "|" + (escapePattern(incomplete)) + ").+$", "g");

updateTaskListItem = function(source, itemIndex, checked) {
  var clean, index, line, result;
  clean = source.replace(/\r/g, '').replace(codeFencesPattern, '').replace(itemsInParasPattern, '').split("\n");
  index = 0;
  result = (function() {
    var i, len, ref, results;
    ref = source.split("\n");
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      line = ref[i];
      if (indexOf.call(clean, line) >= 0 && line.match(itemPattern)) {
        index += 1;
        if (index === itemIndex) {
          line = checked ? line.replace(incompletePattern, complete) : line.replace(completePattern, incomplete);
        }
      }
      results.push(line);
    }
    return results;
  })();
  return result.join("\n");
};

updateTaskList = function($item) {
  var $container, $field, checked, event, index;
  $container = $item.closest('.js-task-list-container');
  $field = $container.find('.js-task-list-field');
  index = 1 + $container.find('.task-list-item-checkbox').index($item);
  checked = $item.prop('checked');
  event = $.Event('tasklist:change');
  $field.trigger(event, [index, checked]);
  if (!event.isDefaultPrevented()) {
    $field.val(updateTaskListItem($field.val(), index, checked));
    $field.trigger('change');
    return $field.trigger('tasklist:changed', [index, checked]);
  }
};

$(document).on('change', '.task-list-item-checkbox', function() {
  return updateTaskList($(this));
});

enableTaskList = function($container) {
  if ($container.find('.js-task-list-field').length > 0) {
    $container.find('.task-list-item').addClass('enabled').find('.task-list-item-checkbox').attr('disabled', null);
    return $container.addClass('is-task-list-enabled').trigger('tasklist:enabled');
  }
};

enableTaskLists = function($containers) {
  var container, i, len, results;
  results = [];
  for (i = 0, len = $containers.length; i < len; i++) {
    container = $containers[i];
    results.push(enableTaskList($(container)));
  }
  return results;
};

disableTaskList = function($container) {
  $container.find('.task-list-item').removeClass('enabled').find('.task-list-item-checkbox').attr('disabled', 'disabled');
  return $container.removeClass('is-task-list-enabled').trigger('tasklist:disabled');
};

disableTaskLists = function($containers) {
  var container, i, len, results;
  results = [];
  for (i = 0, len = $containers.length; i < len; i++) {
    container = $containers[i];
    results.push(disableTaskList($(container)));
  }
  return results;
};

$.fn.taskList = function(method) {
  var $container, methods;
  $container = $(this).closest('.js-task-list-container');
  methods = {
    enable: enableTaskLists,
    disable: disableTaskLists
  };
  return methods[method || 'enable']($container);
};
