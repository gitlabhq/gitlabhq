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
