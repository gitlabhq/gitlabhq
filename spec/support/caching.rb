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

  config.around(:each, :use_clean_rails_redis_caching) do |example|
    original_null_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(**Gitlab::Redis::Cache.active_support_config)

    redis_cache_cleanup!

    example.run

    redis_cache_cleanup!

    Rails.cache = original_null_store
  end

  config.around(:each, :use_clean_rails_repository_cache_store_caching) do |example|
    original_null_store = Rails.cache
    Rails.cache = Gitlab::Redis::RepositoryCache.cache_store

    redis_repository_cache_cleanup!

    example.run

    redis_repository_cache_cleanup!

    Rails.cache = original_null_store
  end

  config.around(:each, :use_sql_query_cache) do |example|
    base_models = Gitlab::Database.database_base_models_with_gitlab_shared.values
    inner_proc = proc { example.run }
    base_models.inject(inner_proc) { |proc, base_model| proc { base_model.cache { proc.call } } }.call
  end
end
