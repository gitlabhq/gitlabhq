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
