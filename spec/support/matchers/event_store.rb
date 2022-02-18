# frozen_string_literal: true

RSpec::Matchers.define :event_type do |event_class|
  match do |actual|
    actual.instance_of?(event_class) &&
      actual.data == @expected_data
  end

  chain :containing do |expected_data|
    @expected_data = expected_data
  end
end
