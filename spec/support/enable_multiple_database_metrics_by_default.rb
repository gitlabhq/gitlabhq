# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    # Enable this by default in all tests so it behaves like a FF
    stub_env('GITLAB_MULTIPLE_DATABASE_METRICS', '1')
  end
end
