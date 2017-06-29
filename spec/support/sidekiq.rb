require 'sidekiq/testing'

Sidekiq::Testing.server_middleware do |chain|
  chain.add Gitlab::SidekiqStatus::ServerMiddleware
end

RSpec.configure do |config|
  config.after(:each, :sidekiq) do
    Sidekiq::Worker.clear_all
  end
end
