# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning, feature_category: :database do
  include Database::PartitioningHelpers
  include Database::TableSchemaHelpers

  let(:main_connection) { ApplicationRecord.connection }

  before do
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
  end

  around do |example|
    previously_registered_models = described_class.registered_models.dup
    described_class.instance_variable_set(:@registered_models, Set.new)

    previously_registered_tables = described_class.registered_tables.dup
    described_class.instance_variable_set(:@registered_tables, Set.new)

    example.run

    described_class.instance_variable_set(:@registered_models, previously_registered_models)
    described_class.instance_variable_set(:@registered_tables, previously_registered_tables)
  end

  describe '.register_models' do
    context 'ensure that the registered models have partitioning strategy' do
      it 'fails when partitioning_strategy is not specified for the model' do
        model = Class.new(ApplicationRecord)
        expect { described_class.register_models([model]) }.to raise_error(/should have partitioning strategy defined/)
      end
    end
  end

  describe '.sync_partitions_ignore_db_error' do
    it 'calls sync_partitions' do
      expect(described_class).to receive(:sync_partitions).with(analyze: false)

      described_class.sync_partitions_ignore_db_error
    end

    [ActiveRecord::ActiveRecordError, PG::Error].each do |error|
      context "when #{error} is raised" do
        before do
          expect(described_class).to receive(:sync_partitions)
            .and_raise(error)
        end

        it 'ignores it' do
          described_class.sync_partitions_ignore_db_error
        end
      end
    end

    context 'when DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP is set' do
      before do
        stub_env('DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP', '1')
      end

      it 'does not call sync_partitions' do
        expect(described_class).not_to receive(:sync_partitions)

        described_class.sync_partitions_ignore_db_error
      end
    end
  end

  describe '.sync_partitions' do
    let(:ci_connection) { Ci::ApplicationRecord.connection }
    let(:table_names) { %w[_test_partitioning_test1 _test_partitioning_test2] }
    let(:models) do
      [
        Class.new(ApplicationRecord) do
          include PartitionedTable

          self.table_name = :_test_partitioning_test1
          partitioned_by :created_at, strategy: :monthly
        end,
        Class.new(Gitlab::Database::Partitioning::TableWithoutModel).tap do |klass|
          klass.table_name = :_test_partitioning_test2
          klass.partitioned_by(:created_at, strategy: :monthly)
          klass.limit_connection_names = %i[main]
        end
      ]
    end

    before do
      table_names.each do |table_name|
        execute_on_each_database(<<~SQL)
          CREATE TABLE #{table_name} (
            id serial not null,
            created_at timestamptz not null,
            PRIMARY KEY (id, created_at))
          PARTITION BY RANGE (created_at);
        SQL
      end
    end

    it 'manages partitions for each given model' do
      expect { described_class.sync_partitions(models) }
        .to change { find_partitions(table_names.first).size }.from(0)
        .and change { find_partitions(table_names.last).size }.from(0)
    end

    context 'for analyze' do
      let(:analyze_regex) { /ANALYZE / }
      let(:analyze) { true }

      shared_examples_for 'not running analyze' do
        specify do
          control = ActiveRecord::QueryRecorder.new { described_class.sync_partitions(analyze: analyze) }
          expect(control.occurrences).not_to include(analyze_regex)
        end
      end

      context 'when analyze_interval is not set' do
        it_behaves_like 'not running analyze'

        context 'when analyze is set to false' do
          it_behaves_like 'not running analyze'
        end
      end

      context 'when analyze_interval is set' do
        let(:models) do
          [
            Class.new(ApplicationRecord) do
              include PartitionedTable

              self.table_name = :_test_partitioning_test1
              partitioned_by :created_at, strategy: :monthly, analyze_interval: 1.week
            end,
            Class.new(Gitlab::Database::Partitioning::TableWithoutModel).tap do |klass|
              klass.table_name = :_test_partitioning_test2
              klass.partitioned_by(:created_at, strategy: :monthly, analyze_interval: 1.week)
              klass.limit_connection_names = %i[main]
            end
          ]
        end

        it 'runs analyze' do
          control = ActiveRecord::QueryRecorder.new { described_class.sync_partitions(models, analyze: analyze) }
          expect(control.occurrences).to include(analyze_regex)
        end

        context 'analyze is false' do
          let(:analyze) { false }

          it_behaves_like 'not running analyze'
        end
      end
    end

    context 'with multiple databases' do
      it 'creates partitions in each database' do
        skip_if_shared_database(:ci)

        expect { described_class.sync_partitions(models) }
          .to change { find_partitions(table_names.first, conn: main_connection).size }.from(0)
          .and change { find_partitions(table_names.last, conn: main_connection).size }.from(0)
          .and change { find_partitions(table_names.first, conn: ci_connection).size }.from(0)
          .and change { find_partitions(table_names.last, conn: ci_connection).size }.from(0)
      end

      it 'does not create partitions in each database if restricted' do
        skip_if_shared_database(:ci)

        expect { described_class.sync_partitions(models, owner_db_only: true) }
          .to change { find_partitions(table_names.first, conn: main_connection).size }.from(0)
          .and change { find_partitions(table_names.last, conn: main_connection).size }.from(0)
          .and change { find_partitions(table_names.first, conn: ci_connection).size }.by_at_most(0)
          .and change { find_partitions(table_names.last, conn: ci_connection).size }.by_at_most(0)
      end
    end

    context 'without ci database' do
      it 'only creates partitions for main database' do
        skip_if_database_exists(:ci)

        allow(Gitlab::Database::Partitioning::PartitionManager).to receive(:new).and_call_original

        # Also, in the case where `ci` database is shared with `main` database,
        # check that we do not run PartitionManager again for ci connection as
        # that is redundant.
        expect(Gitlab::Database::Partitioning::PartitionManager).not_to receive(:new)
          .with(anything, connection: ci_connection).and_call_original

        expect { described_class.sync_partitions(models) }
          .to change { find_partitions(table_names.first, conn: main_connection).size }.from(0)
          .and change { find_partitions(table_names.last, conn: main_connection).size }.from(0)
      end
    end

    context 'when no partitioned models are given' do
      it 'manages partitions for each registered model' do
        described_class.register_models([models.first])
        described_class.register_tables(
          [
            {
              table_name: table_names.last,
              partitioned_column: :created_at,
              strategy: :monthly
            }
          ])

        expect { described_class.sync_partitions }
          .to change { find_partitions(table_names.first).size }.from(0)
          .and change { find_partitions(table_names.last).size }.from(0)
      end
    end

    context 'when only a specific database is requested' do
      let(:ci_model) do
        Class.new(Ci::ApplicationRecord) do
          include PartitionedTable

          self.table_name = :_test_partitioning_test3
          partitioned_by :created_at, strategy: :monthly
        end
      end

      before do
        skip_if_shared_database(:ci)

        (table_names + [:_test_partitioning_test3]).each do |table_name|
          execute_on_each_database("DROP TABLE IF EXISTS #{table_name}")

          execute_on_each_database(<<~SQL)
            CREATE TABLE #{table_name} (
              id serial not null,
              created_at timestamptz not null,
              PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);
          SQL
        end
      end

      after do
        (table_names + [:_test_partitioning_test3]).each do |table_name|
          ci_connection.execute("DROP TABLE IF EXISTS #{table_name}")
        end
      end

      it 'manages partitions for models for the given database', :aggregate_failures do
        expect { described_class.sync_partitions([models.first, ci_model], only_on: 'ci') }
          .to change { find_partitions(ci_model.table_name, conn: ci_connection).size }.from(0)

        expect(find_partitions(models.first.table_name, conn: main_connection).size).to eq(0)
        expect(find_partitions(models.first.table_name, conn: ci_connection).size).to eq(0)
        expect(find_partitions(ci_model.table_name, conn: main_connection).size).to eq(0)
      end
    end

    context 'when partition_manager_sync_partitions feature flag is disabled' do
      before do
        described_class.register_models(models)
        stub_feature_flags(partition_manager_sync_partitions: false)
      end

      it 'skips sync_partitions' do
        expect(described_class::PartitionManager).not_to receive(:new)
        expect(described_class).to receive(:sync_partitions)
          .and_call_original

        described_class.sync_partitions(models)
      end
    end

    context 'when disallow_database_ddl_feature_flags feature flag is enabled' do
      before do
        described_class.register_models(models)
        stub_feature_flags(disallow_database_ddl_feature_flags: true)
      end

      it 'skips sync_partitions' do
        expect(described_class::PartitionManager).not_to receive(:new)
        expect(described_class).to receive(:sync_partitions).and_call_original

        described_class.sync_partitions(models)
      end
    end
  end

  describe '.report_metrics' do
    let(:model1) { double('model') }
    let(:model2) { double('model') }

    let(:partition_monitoring_class) { described_class::PartitionMonitoring }

    context 'when no partitioned models are given' do
      it 'reports metrics for each registered model' do
        expect_next_instance_of(partition_monitoring_class) do |partition_monitor|
          expect(partition_monitor).to receive(:report_metrics_for_model).with(model1)
          expect(partition_monitor).to receive(:report_metrics_for_model).with(model2)
        end

        expect(Gitlab::Database::EachDatabase).to receive(:each_model_connection)
          .with(described_class.__send__(:registered_models))
          .and_yield(model1)
          .and_yield(model2)

        described_class.report_metrics
      end
    end

    context 'when partitioned models are given' do
      it 'reports metrics for each given model' do
        expect_next_instance_of(partition_monitoring_class) do |partition_monitor|
          expect(partition_monitor).to receive(:report_metrics_for_model).with(model1)
          expect(partition_monitor).to receive(:report_metrics_for_model).with(model2)
        end

        expect(Gitlab::Database::EachDatabase).to receive(:each_model_connection)
          .with([model1, model2])
          .and_yield(model1)
          .and_yield(model2)

        described_class.report_metrics([model1, model2])
      end
    end
  end

  describe '.drop_detached_partitions' do
    let(:table_names) { %w[_test_detached_test_partition1 _test_detached_test_partition2] }

    before do
      table_names.each do |table_name|
        connection.create_table("#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{table_name}")

        Postgresql::DetachedPartition.create!(table_name: table_name, drop_after: 1.year.ago)
      end
    end

    it 'drops detached partitions for each database' do
      expect(Gitlab::Database::EachDatabase).to receive(:each_connection).and_yield

      expect { described_class.drop_detached_partitions }
        .to change { Postgresql::DetachedPartition.count }.from(2).to(0)
        .and change { table_exists?(table_names.first) }.from(true).to(false)
        .and change { table_exists?(table_names.last) }.from(true).to(false)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(partition_manager_sync_partitions: false)
      end

      it 'does not call the DetachedPartitionDropper' do
        expect(Gitlab::Database::Partitioning::DetachedPartitionDropper).not_to receive(:new)

        described_class.drop_detached_partitions
      end
    end

    context 'when the feature disallow DDL feature flags is enabled' do
      before do
        stub_feature_flags(disallow_database_ddl_feature_flags: true)
      end

      it 'does not call the DetachedPartitionDropper' do
        expect(Gitlab::Database::Partitioning::DetachedPartitionDropper).not_to receive(:new)

        described_class.drop_detached_partitions
      end
    end

    def table_exists?(table_name)
      table_oid(table_name).present?
    end
  end
end
