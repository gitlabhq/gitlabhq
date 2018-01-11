# Select2 ajax programmatic helper
# It allows you to select value from select2
#
# Params
#   value - real value of selected item
#   opts - options containing css selector
#
# Usage:
#
#   select2(2, from: '#user_ids')
#

module Select2Helper
  def select2(value, options = {})
    raise ArgumentError, 'options must be a Hash' unless options.is_a?(Hash)

    selector = options.fetch(:from)

    first(selector, visible: false)

    if options[:multiple]
      execute_script("$('#{selector}').select2('val', ['#{value}']).trigger('change');")
    else
      execute_script("$('#{selector}').select2('val', '#{value}').trigger('change');")
    end
  end

  def open_select2(selector)
    execute_script("$('#{selector}').select2('open');")
  end

  def scroll_select2_to_bottom(selector)
    evaluate_script "$('#{selector}').scrollTop($('#{selector}')[0].scrollHeight); $('#{selector}');"
  end
end
