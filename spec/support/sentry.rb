# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:example, :sentry) do |example|
    dsn = Sentry.get_current_client.configuration.dsn
    Sentry.get_current_client.configuration.dsn = 'dummy://b44a0828b72421a6d8e99efd68d44fa8@example.com/42'
    begin
      example.run
    ensure
      Sentry.get_current_client.configuration.dsn = dsn.to_s.presence
    end
  end
end
