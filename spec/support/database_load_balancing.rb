# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :db_load_balancing) do
    allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)

    proxy = ::Gitlab::Database::LoadBalancing::ConnectionProxy.new([Gitlab::Database.main.config['host']])

    allow(ActiveRecord::Base).to receive(:load_balancing_proxy).and_return(proxy)

    ::Gitlab::Database::LoadBalancing::Session.clear_session
    redis_shared_state_cleanup!
  end

  config.after(:each, :db_load_balancing) do
    ::Gitlab::Database::LoadBalancing::Session.clear_session
    redis_shared_state_cleanup!
  end
end
