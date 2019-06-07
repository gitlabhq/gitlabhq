# frozen_string_literal: true

RSpec::Matchers.define :eq_pem do |expected_pem_string|
  match do |actual|
    actual.to_pem == expected_pem_string
  end

  description do
    "contain pem #{expected_pem_string}"
  end
end
