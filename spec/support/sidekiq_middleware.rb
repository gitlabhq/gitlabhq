# frozen_string_literal: true

require 'sidekiq/testing'

# rubocop:disable RSpec/ModifySidekiqMiddleware
module SidekiqMiddleware
  def with_sidekiq_server_middleware(&block)
    Sidekiq::Testing.server_middleware.clear
    Sidekiq::Testing.server_middleware(&block)
  ensure
    Sidekiq::Testing.server_middleware.clear
  end
end
# rubocop:enable RSpec/ModifySidekiqMiddleware

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
