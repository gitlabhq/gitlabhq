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
# deployment sidekiq worker is executed separately). To avoid increasing
# SQL limit counter, query limiting is disabled during Sidekiq block
class DisableQueryLimit
  def call(worker_instance, msg, queue)
    ::Gitlab::QueryLimiting.disable!('https://mock-issue')
    yield
  ensure
    ::Gitlab::QueryLimiting.enable!
  end
end

# When running `Sidekiq::Testing.inline!` each job is using a request-store.
# This middleware makes sure the values don't leak into eachother.
class IsolatedRequestStore
  def call(_worker, msg, queue)
    old_store = RequestStore.store.dup
    RequestStore.clear!

    yield

    RequestStore.store = old_store
  end
end
