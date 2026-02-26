# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'load_balancing', :delete, :reestablished_active_record_base, feature_category: :cell do
  subject(:initialize_load_balancer) do
    load Rails.root.join('config/initializers/load_balancing.rb')
  end

  before do
    # Stub out middleware call, as not idempotent
    allow(Gitlab::Application.instance.middleware).to receive(:use)
  end

  context 'with replica hosts configured' do
    before do
      # Setup host-based load balancing
      # Patch in our load balancer config, simply pointing at the test database twice
      allow(Gitlab::Database::LoadBalancing::Configuration).to receive(:for_model) do |base_model|
        db_host = base_model.connection_pool.db_config.host

        Gitlab::Database::LoadBalancing::Configuration.new(base_model, [db_host, db_host])
      end
    end

    after do
      # reset load balancing to original state
      allow(Gitlab::Database::LoadBalancing::Configuration).to receive(:for_model).and_call_original
      allow(Gitlab::Cluster::LifecycleEvents).to receive(:in_clustered_puma?).and_call_original

      load Rails.root.join('config/initializers/load_balancing.rb')
    end

    it 'configures load balancer with two replica hosts' do
      expect(ApplicationRecord.connection.load_balancer.configuration.hosts.size).to eq(0)
      expect(Ci::ApplicationRecord.connection.load_balancer.configuration.hosts.size).to eq(0)

      initialize_load_balancer

      expect(ApplicationRecord.connection.load_balancer.configuration.hosts.size).to eq(2)
      expect(Ci::ApplicationRecord.connection.load_balancer.configuration.hosts.size).to eq(2)
    end

    context 'for a clustered puma worker' do
      let!(:group) { create(:group, name: 'my group') }

      before do
        # Pretend we are in clustered environment
        allow(Gitlab::Cluster::LifecycleEvents).to receive(:in_clustered_puma?).and_return(true)
      end

      it 'configures load balancer to have two replica hosts' do
        initialize_load_balancer

        simulate_puma_worker do
          expect(ApplicationRecord.connection.load_balancer.configuration.hosts.size).to eq(2)
          expect(Ci::ApplicationRecord.connection.load_balancer.configuration.hosts.size).to eq(2)
        end
      end

      # We tried using Process.fork for a more realistic simulation
      # but run into bugs where GPRC cannot be used before forking processes.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/333184#note_1081658113
      def simulate_puma_worker
        # Called in https://github.com/rails/rails/blob/6-1-stable/activerecord/lib/active_record/connection_adapters/pool_config.rb#L73
        ActiveRecord::ConnectionAdapters::PoolConfig.discard_pools!

        # Called in config/puma.rb
        Gitlab::Cluster::LifecycleEvents.do_worker_start

        yield
      end

      it 'makes a read query successfully' do
        # Clear any previous sticky writes
        ::Gitlab::Database::LoadBalancing::SessionMap.clear_session

        initialize_load_balancer

        group_name = simulate_puma_worker do
          Group.find_by_name('my group').name
        end

        expect(group_name).to eq(group.name)
      end

      it 'makes a write query successfully' do
        initialize_load_balancer

        expect do
          simulate_puma_worker do
            Group.touch_all
          end

          group.reload
        end.to change(group, :updated_at)
      end
    end
  end
end
