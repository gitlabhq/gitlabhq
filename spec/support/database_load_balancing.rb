# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :db_load_balancing) do
    config = Gitlab::Database::LoadBalancing::Configuration
      .new(ActiveRecord::Base, [Gitlab::Database.main.config['host']])
    lb = ::Gitlab::Database::LoadBalancing::LoadBalancer.new(config)
    proxy = ::Gitlab::Database::LoadBalancing::ConnectionProxy.new(lb)

    allow(ActiveRecord::Base).to receive(:load_balancing_proxy).and_return(proxy)

    ::Gitlab::Database::LoadBalancing::Session.clear_session
    redis_shared_state_cleanup!
  end

  config.after(:each, :db_load_balancing) do
    ::Gitlab::Database::LoadBalancing::Session.clear_session
    redis_shared_state_cleanup!
  end
end
