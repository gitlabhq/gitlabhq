# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :database_replica) do |example|
    old_proxies = {}

    Gitlab::Database::LoadBalancing.base_models.each do |model|
      old_proxies[model] = [model.load_balancer, model.connection, model.sticking]

      config = Gitlab::Database::LoadBalancing::Configuration
        .new(model, [model.connection_db_config.configuration_hash[:host]])

      model.load_balancer = Gitlab::Database::LoadBalancing::LoadBalancer.new(config)
      model.sticking = Gitlab::Database::LoadBalancing::Sticking.new(model.load_balancer)
      model.connection = Gitlab::Database::LoadBalancing::ConnectionProxy.new(model.load_balancer)
    end

    Gitlab::Database::LoadBalancing::SessionMap.clear_session
    redis_shared_state_cleanup!

    example.run

    Gitlab::Database::LoadBalancing::SessionMap.clear_session
    redis_shared_state_cleanup!

    old_proxies.each do |model, proxy|
      model.load_balancer, model.connection, model.sticking = proxy
    end
  end
end
