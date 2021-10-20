# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :database_replica) do |example|
    old_proxies = []

    Gitlab::Database::LoadBalancing.base_models.each do |model|
      config = Gitlab::Database::LoadBalancing::Configuration
        .new(model, [model.connection_db_config.configuration_hash[:host]])
      lb = Gitlab::Database::LoadBalancing::LoadBalancer.new(config)

      old_proxies << [model, model.connection]

      model.connection =
        Gitlab::Database::LoadBalancing::ConnectionProxy.new(lb)
    end

    Gitlab::Database::LoadBalancing::Session.clear_session
    redis_shared_state_cleanup!

    example.run

    Gitlab::Database::LoadBalancing::Session.clear_session
    redis_shared_state_cleanup!

    old_proxies.each do |(model, proxy)|
      model.connection = proxy
    end
  end
end
