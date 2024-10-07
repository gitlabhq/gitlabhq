# frozen_string_literal: true

RSpec.shared_context 'when tracking WAL location reference' do
  let(:current_location) { '0/D525E3A8' }

  around do |example|
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
    example.run
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  def expect_tracked_locations_when_replicas_available
    {}.tap do |locations|
      Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
        expect(lb.host).to receive(:database_replica_location).and_return(current_location)

        locations[lb.name] = current_location
      end
    end
  end

  def expect_tracked_locations_when_no_replicas_available
    {}.tap do |locations|
      Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
        expect(lb).to receive(:host).at_least(:once).and_return(nil)
        expect(lb).to receive(:primary_write_location).and_return(current_location)

        locations[lb.name] = current_location
      end
    end
  end

  def expect_tracked_locations_from_primary_only
    {}.tap do |locations|
      Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
        expect(lb).to receive(:primary_write_location).and_return(current_location)

        locations[lb.name] = current_location
      end
    end
  end

  def stub_load_balancing_disabled!
    Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
      allow(lb).to receive(:primary_only?).and_return(true)
    end
  end

  def stub_load_balancing_enabled!
    Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
      allow(lb).to receive(:primary_only?).and_return(false)
    end
  end

  def stub_no_writes_performed!
    Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
      allow(Gitlab::Database::LoadBalancing::SessionMap.current(lb)).to receive(:use_primary?).and_return(false)
    end
  end

  def stub_write_performed!
    Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
      allow(Gitlab::Database::LoadBalancing::SessionMap.current(lb)).to receive(:use_primary?).and_return(true)
    end
  end

  def stub_replica_available!(available)
    ::Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
      result = if available
                 ::Gitlab::Database::LoadBalancing::LoadBalancer::ANY_CAUGHT_UP
               else
                 ::Gitlab::Database::LoadBalancing::LoadBalancer::NONE_CAUGHT_UP
               end

      allow(lb).to receive(:select_up_to_date_host).with(current_location).and_return(result)
    end
  end
end
