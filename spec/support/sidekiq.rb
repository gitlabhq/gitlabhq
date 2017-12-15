require 'sidekiq/testing'

Sidekiq::Testing.server_middleware do |chain|
  chain.add Gitlab::SidekiqStatus::ServerMiddleware
end

RSpec.configure do |config|
  config.around(:each, :sidekiq) do |example|
    Sidekiq::Testing.inline! do
      example.run
    end
  end

  config.after(:each, :sidekiq, :redis) do
    Sidekiq.redis { |redis| redis.flushdb }
  end
end
