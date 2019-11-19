# frozen_string_literal: true

require 'sidekiq/testing'

# If Sidekiq::Testing.inline! is used, SQL transactions done inside
# Sidekiq worker are included in the SQL query limit (in a real
# deployment sidekiq worker is executed separately). To avoid
# increasing SQL limit counter, the request is marked as whitelisted
# during Sidekiq block
class DisableQueryLimit
  def call(worker_instance, msg, queue)
    transaction = Gitlab::QueryLimiting::Transaction.current

    if !transaction.respond_to?(:whitelisted) || transaction.whitelisted
      yield
    else
      transaction.whitelisted = true
      yield
      transaction.whitelisted = false
    end
  end
end

Sidekiq::Testing.server_middleware do |chain|
  chain.add Gitlab::SidekiqStatus::ServerMiddleware
  chain.add DisableQueryLimit
end

RSpec.configure do |config|
  config.around(:each, :sidekiq) do |example|
    Sidekiq::Worker.clear_all
    example.run
    Sidekiq::Worker.clear_all
  end

  config.after(:each, :sidekiq, :redis) do
    Sidekiq.redis do |connection|
      connection.redis.flushdb
    end
  end

  # As we'll review the examples with this tag, we should either:
  # - fix the example to not require Sidekiq inline mode (and remove this tag)
  # - explicitly keep the inline mode and change the tag for `:sidekiq_inline` instead
  config.around(:example, :sidekiq_might_not_need_inline) do |example|
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.inline! { example.run }
    Sidekiq::Worker.clear_all
  end

  config.around(:example, :sidekiq_inline) do |example|
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.inline! { example.run }
    Sidekiq::Worker.clear_all
  end
end
