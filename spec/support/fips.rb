# frozen_string_literal: true
# rubocop: disable RSpec/EnvAssignment

RSpec.configure do |config|
  config.around(:each, :fips_mode) do |example|
    prior_value = ENV["FIPS_MODE"]
    ENV["FIPS_MODE"] = "true"

    example.run

    ENV["FIPS_MODE"] = prior_value
  end
end

# rubocop: enable RSpec/EnvAssignment
