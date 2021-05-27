# frozen_string_literal: true

RSpec.shared_context 'clear DB Load Balancing configuration' do
  def clear_load_balancing_configuration
    proxy = ::Gitlab::Database::LoadBalancing.instance_variable_get(:@proxy)
    proxy.load_balancer.release_host if proxy
    ::Gitlab::Database::LoadBalancing.instance_variable_set(:@proxy, nil)

    ::Gitlab::Database::LoadBalancing.remove_instance_variable(:@feature_available) if ::Gitlab::Database::LoadBalancing.instance_variable_defined?(:@feature_available)

    ::Gitlab::Database::LoadBalancing::Session.clear_session
  end

  around do |example|
    clear_load_balancing_configuration

    example.run

    clear_load_balancing_configuration
  end
end
