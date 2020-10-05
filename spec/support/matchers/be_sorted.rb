# frozen_string_literal: true

# Assert that this collection is sorted by argument and order
#
# By default, this checks that the collection is sorted ascending
# but you can check order by specific field and order by passing
# them, eg:
#
# ```
# expect(collection).to be_sorted(:field, :desc)
# ```
RSpec::Matchers.define :be_sorted do |by, order = :asc|
  match do |actual|
    next true unless actual.present? # emtpy collection is sorted

    actual
      .then { |collection| by ? collection.sort_by(&by) : collection.sort }
      .then { |sorted_collection| order.to_sym == :desc ? sorted_collection.reverse : sorted_collection }
      .then { |sorted_collection| sorted_collection == actual }
  end
end
