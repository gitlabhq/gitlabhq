# frozen_string_literal: true

require 'oj'

def parameterized_test_matrix(invalid: false)
  test_cases_path = File.join(
    File.expand_path(__dir__), '../../../../fixtures/lib/sbom/package-url-test-cases.json')
  test_cases = Gitlab::Json.parse(File.read(test_cases_path))

  test_cases
    .filter { |test_case| test_case.delete('is_invalid') == invalid }
    .each_with_object({}) do |test_case, memo|
    description = test_case.delete('description')
    memo[description] = test_case.symbolize_keys
  end
end

RSpec.shared_context 'with valid purl examples' do
  where do
    parameterized_test_matrix(invalid: false)
  end
end

RSpec.shared_context 'with invalid purl examples' do
  where do
    parameterized_test_matrix(invalid: true)
  end
end
