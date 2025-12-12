# frozen_string_literal: true

# Matcher specific to Gitlab::Database::Aggregation::Engine class testing
RSpec::Matchers.define :execute_aggregation do |request|
  chain :and_return do |expected_data|
    @expected_data = expected_data
  end

  chain :with_errors do |expected_errors|
    @expected_errors = expected_errors
  end

  match do |engine|
    response = engine.execute(request)

    @actual_data = response[:data]&.to_a&.map(&:with_indifferent_access)
    @actual_errors = response[:errors]&.to_a

    if @expected_data
      response.success? && values_match?(@expected_data, @actual_data)
    elsif @expected_errors
      response.error? && values_match?(@expected_errors, @actual_errors)
    end
  end

  failure_message do |engine|
    if @expected_data
      "expected #{engine.class} to execute aggregation and return #{@expected_data.inspect}, " \
        "but got #{@actual_data.inspect}"
    elsif @expected_errors
      "expected #{engine.class} to execute aggregation with errors #{@expected_errors.inspect}, " \
        "but got #{@actual_errors.inspect}"
    end
  end
end
