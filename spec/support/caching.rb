# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :use_clean_rails_memory_store_caching) do |example|
    caching_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    example.run

    Rails.cache = caching_store
  end

  config.around(:each, :use_clean_rails_memory_store_fragment_caching) do |example|
    caching_store = ActionController::Base.cache_store
    ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.perform_caching = true

    example.run

    ActionController::Base.perform_caching = false
    ActionController::Base.cache_store = caching_store
  end

  config.around(:each, :use_sql_query_cache) do |example|
    ActiveRecord::Base.cache do
      example.run
    end
  end
end
