# frozen_string_literal: true

RSpec.shared_context 'rack attack cache store' do
  around do |example|
    # Restore the store we replaced, not Rails.cache: an outer around hook can still hold Rails.cache as a memory store
    # here, and Rack::Attack would keep counting in it for later examples.
    original_store = Rack::Attack.cache.store

    # Instead of test environment's :null_store so the throttles can increment
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    example.run
  ensure
    Rack::Attack.cache.store = original_store
  end
end
