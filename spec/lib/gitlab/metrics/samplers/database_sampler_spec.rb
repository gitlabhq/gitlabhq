# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::DatabaseSampler do
  subject { described_class.new }

  it_behaves_like 'metrics sampler', 'DATABASE_SAMPLER'

  describe '#sample' do
    let(:main_load_balancer) do
      double(:main_load_balancer, host_list: main_host_list, configuration: main_configuration, primary_only?: false)
    end

    let(:main_configuration) { double(:configuration, connection_specification_name: 'ActiveRecord::Base') }
    let(:main_host_list) { double(:host_list, hosts: [main_replica_host]) }
    let(:main_replica_host) { double(:host, pool: main_replica_pool, host: 'main-replica-host', port: 2345) }
    let(:main_replica_pool) do
      double(:main_replica_pool, db_config: double(:main_replica_db_config, name: 'main_replica'), stat: stats)
    end

    let(:stats) do
      { size: 123, connections: 100, busy: 10, dead: 5, idle: 85, waiting: 1 }
    end

    let(:ci_load_balancer) do
      double(:ci_load_balancer, host_list: ci_host_list, configuration: ci_configuration, primary_only?: false)
    end

    let(:ci_configuration) { double(:configuration, connection_specification_name: 'Ci::ApplicationRecord') }
    let(:ci_host_list) { double(:host_list, hosts: [ci_replica_host]) }
    let(:ci_replica_host) { double(:host, pool: ci_replica_pool, host: 'ci-replica-host', port: 3456) }
    let(:ci_replica_pool) do
      double(:ci_replica_pool, db_config: double(:ci_replica_db_config, name: 'ci_replica'), stat: stats)
    end

    let(:main_labels) do
      {
        class: 'ActiveRecord::Base',
        host: ApplicationRecord.database.config['host'],
        port: ApplicationRecord.database.config['port'],
        db_config_name: 'main'
      }
    end

    let(:ci_labels) do
      {
        class: 'Ci::ApplicationRecord',
        host: Ci::ApplicationRecord.database.config['host'],
        port: Ci::ApplicationRecord.database.config['port'],
        db_config_name: 'ci'
      }
    end

    let(:main_replica_labels) do
      {
        class: 'ActiveRecord::Base',
        host: 'main-replica-host',
        port: 2345,
        db_config_name: 'main_replica'
      }
    end

    let(:ci_replica_labels) do
      {
        class: 'Ci::ApplicationRecord',
        host: 'ci-replica-host',
        port: 3456,
        db_config_name: 'ci_replica'
      }
    end

    before do
      described_class::METRIC_DESCRIPTIONS.each_key do |metric|
        allow(subject.metrics[metric]).to receive(:set)
      end

      allow(Gitlab::Database).to receive(:database_base_models)
        .and_return({ main: ActiveRecord::Base, ci: Ci::ApplicationRecord })
    end

    context 'when all base models are connected', :add_ci_connection do
      it 'samples connection pool statistics for all primaries' do
        expect_metrics_with_labels(main_labels)
        expect_metrics_with_labels(ci_labels)

        subject.sample
      end

      context 'when replica hosts are configured' do
        before do
          allow(Gitlab::Database::LoadBalancing).to receive(:each_load_balancer)
            .and_return([main_load_balancer, ci_load_balancer].to_enum)
        end

        it 'samples connection pool statistics for primaries and replicas' do
          expect_metrics_with_labels(main_labels)
          expect_metrics_with_labels(ci_labels)
          expect_metrics_with_labels(main_replica_labels)
          expect_metrics_with_labels(ci_replica_labels)

          subject.sample
        end
      end
    end

    context 'when a base model is not connected', :add_ci_connection do
      before do
        allow(Ci::ApplicationRecord).to receive(:connected?).and_return(false)
      end

      it 'records no samples for that primary' do
        expect_metrics_with_labels(main_labels)
        expect_no_metrics_with_labels(ci_labels)

        subject.sample
      end

      context 'when the base model has replica connections' do
        before do
          allow(Gitlab::Database::LoadBalancing).to receive(:each_load_balancer)
            .and_return([main_load_balancer, ci_load_balancer].to_enum)
        end

        it 'still records the replica metrics' do
          expect_metrics_with_labels(main_labels)
          expect_metrics_with_labels(main_replica_labels)
          expect_no_metrics_with_labels(ci_labels)
          expect_metrics_with_labels(ci_replica_labels)

          subject.sample
        end
      end
    end

    def expect_metrics_with_labels(labels)
      expect(subject.metrics[:size]).to receive(:set).with(labels, a_value >= 1)
      expect(subject.metrics[:connections]).to receive(:set).with(labels, a_value >= 1)
      expect(subject.metrics[:busy]).to receive(:set).with(labels, a_value >= 1)
      expect(subject.metrics[:dead]).to receive(:set).with(labels, a_value >= 0)
      expect(subject.metrics[:waiting]).to receive(:set).with(labels, a_value >= 0)
    end

    def expect_no_metrics_with_labels(labels)
      described_class::METRIC_DESCRIPTIONS.each_key do |metric|
        expect(subject.metrics[metric]).not_to receive(:set).with(labels, anything)
      end
    end
  end
end
