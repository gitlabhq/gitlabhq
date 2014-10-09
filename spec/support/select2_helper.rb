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
  def select2(value, options={})
    raise "Must pass a hash containing 'from'" if not options.is_a?(Hash) or not options.has_key?(:from)

    selector = options[:from]

    if options[:multiple]
      execute_script("$('#{selector}').select2('val', ['#{value}']);")
    else
      execute_script("$('#{selector}').select2('val', '#{value}');")
    end
  end
end
