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

  # Mimic some part of the fips behaviour
  config.before(:each, :fips_mode) do
    allow(OpenSSL::KDF).to receive(:pbkdf2_hmac).and_wrap_original do |method, password, **options|
      raise OpenSSL::KDF::KDFError, "PKCS5_PBKDF2_HMAC: invalid key length" if password.to_s.length < 8

      method.call(password, **options)
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
