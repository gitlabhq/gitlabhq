require 'sidekiq/testing/inline'

Sidekiq::Testing.server_middleware do |chain|
  chain.add Gitlab::SidekiqStatus::ServerMiddleware
end
