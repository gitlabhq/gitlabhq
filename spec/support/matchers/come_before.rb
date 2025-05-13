# frozen_string_literal: true

RSpec::Matchers.define :come_before do |later_element|
  match do |earlier_element|
    @array.index(earlier_element) < @array.index(later_element)
  end

  chain :in do |array|
    @array = array
  end

  failure_message do |earlier_element|
    "expected #{earlier_element.inspect} to come before #{later_element.inspect} in #{@array.inspect}"
  end
end
