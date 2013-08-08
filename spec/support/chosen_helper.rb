# Chosen programmatic helper
# It allows you to select value from chosen select
#
# Params
#   value - real value of selected item
#   opts - options containing css selector
#
# Usage:
#
#   chosen(2, from: '#user_ids')
#

module ChosenHelper
  def chosen(value, options={})
    raise "Must pass a hash containing 'from'" if not options.is_a?(Hash) or not options.has_key?(:from)

    selector = options[:from]

    page.execute_script("$('#{selector}').val('#{value}').trigger('chosen:updated');")
  end
end
