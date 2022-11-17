# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :disable_rate_limiter) do
    allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
  end
end
