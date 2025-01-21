# frozen_string_literal: true

# rubocop: disable RSpec/EnvAssignment

RSpec.configure do |config|
  config.around(:each, :fips_mode) do |example|
    set_fips_mode(true) do
      example.run
    end
  end

  config.around(:each, fips_mode: false) do |example|
    set_fips_mode(false) do
      example.run
    end
  end

  def set_fips_mode(value)
    prior_value = ENV["FIPS_MODE"]
    ENV["FIPS_MODE"] = value.to_s

    yield

    ENV["FIPS_MODE"] = prior_value
  end
end

# rubocop: enable RSpec/EnvAssignment
