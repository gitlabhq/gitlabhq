# frozen_string_literal: true

module StrategyHelpers
  include Rack::Test::Methods
  include ActionDispatch::Assertions::ResponseAssertions
  include Shoulda::Matchers::ActionController
  include OmniAuth::Test::StrategyTestCase

  def auth_hash
    last_request.env['omniauth.auth']
  end

  def self.without_test_mode
    original_mode = OmniAuth.config.test_mode
    original_on_failure = OmniAuth.config.on_failure

    OmniAuth.config.test_mode = false
    OmniAuth.config.on_failure = proc do |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    end

    yield
  ensure
    OmniAuth.config.test_mode = original_mode
    OmniAuth.config.on_failure = original_on_failure
  end
end

RSpec.configure do |config|
  config.include StrategyHelpers, type: :strategy

  config.around(type: :strategy) do |example|
    StrategyHelpers.without_test_mode do
      example.run
    end
  end
end
