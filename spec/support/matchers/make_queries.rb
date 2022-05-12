# frozen_string_literal: true

RSpec::Matchers.define :make_queries do |expected_count = nil|
  supports_block_expectations

  match do |block|
    @recorder = ActiveRecord::QueryRecorder.new(&block)
    @counter = @recorder.count
    if expected_count
      @counter == expected_count
    else
      @counter > 0
    end
  end

  failure_message do |_|
    if expected_count
      "expected to make #{expected_count} queries but made #{@counter} queries"
    else
      "expected to make queries but did not make any"
    end
  end

  failure_message_when_negated do |_|
    if expected_count
      "expected not to make #{expected_count} queries but received #{@counter} queries"
    else
      "expected not to make queries but received #{@counter} queries"
    end
  end
end
