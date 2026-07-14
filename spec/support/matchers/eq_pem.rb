# frozen_string_literal: true

RSpec::Matchers.define :eq_pem do |expected_pem_string|
  match do |actual|
    actual.to_pem == expected_pem_string
  end

  description do
    "contain pem #{expected_pem_string}"
  end

  failure_message do |actual|
    expected_lines = expected_pem_string.lines.count
    actual_lines   = actual.to_pem.lines.count
    if expected_lines == actual_lines
      "expected PEM content to match (both #{expected_lines} lines, but content differs)"
    else
      "expected PEM content to match " \
        "(expected #{expected_lines} lines, got #{actual_lines} lines)"
    end
  end
end
