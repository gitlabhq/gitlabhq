# frozen_string_literal: true

SIGNING_KEY = OpenSSL::PKey::RSA.new(2048)

RSpec.configure do |config|
  config.before do |example|
    # Ensure CI Job Token JWT's can be generated and decoded with the same key
    unless example.metadata[:do_not_stub_ci_job_token_signing_key]
      stub_application_setting(ci_job_token_signing_key: SIGNING_KEY)
    end

    # Prevent CI Job Tokens from expiring during long running tests
    stub_const('Ci::JobToken::Jwt::LEEWAY', 100.minutes)
  end
end
