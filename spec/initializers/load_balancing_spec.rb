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

  context 'when hot reloading' do
    it 'reconfigures load balancing' do
      initialize_load_balancer

      original_models = Gitlab::Database::LoadBalancing.base_model_names.dup
      expect(original_models).not_to be_empty

      # Simulate the LB singleton losing its state (as if it were reloaded).
      Gitlab::Database::LoadBalancing.configure! do |lb|
        lb.base_model_names = []
      end
      expect(Gitlab::Database::LoadBalancing.base_model_names).to be_empty

      configure_load_balancing!

      expect(Gitlab::Database::LoadBalancing.base_model_names).to match_array(original_models)
    end
  end

  describe Gitlab::Database::LoadBalancing do
    describe '.base_models' do
      it 'returns the models to apply load balancing to' do
        models = described_class.base_models

        expect(models).to include(ActiveRecord::Base)
        expect(models).to include(Ci::ApplicationRecord) if Gitlab::Database.has_config?(:ci)
      end

      it 'returns the models as a frozen array' do
        expect(described_class.base_models).to be_frozen
      end
    end
  end

  describe Gitlab::Database::LoadBalancing::Callbacks do
    describe '.configure!' do
      it 'configures track_exception_proc to forward exceptions to ErrorTracking' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                           .with(an_instance_of(Gitlab::Utils::ConcurrentRubyThreadIsUsedError))

        initialize_load_balancer

        Gitlab::Utils.restrict_within_concurrent_ruby do
          expect { ApplicationRecord.connection.execute("SELECT 1") }
            .to raise_error(Gitlab::Utils::ConcurrentRubyThreadIsUsedError)
        end
      end

      it 'configures metrics_host_gauge_proc to set prometheus metrics', :reestablished_active_record_base do
        expect(described_class).to receive(:metrics_host_gauge)
                                     .with({}, 1).and_call_original

        # Metric will be set once configured host list:
        # - 1 host since we only have primary
        # - this test will fail if running CI against replicas
        model = Gitlab::Database::LoadBalancing.base_models.first
        Gitlab::Database::LoadBalancing::Setup.new(model).setup

        metric = ::Prometheus::Client.registry.get(:db_load_balancing_hosts)
        expect(metric).not_to be_nil
        expect(metric.values[{}].get).to eq(1)
      end
    end
  end
end
