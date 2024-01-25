# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing, feature_category: :database, time_travel_to: '2023-01-07T09:44:07Z' do
  include ExclusiveLeaseHelpers
  include Database::DatabaseHelpers

  before do
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
  end

  describe '.invoke' do
    let(:databases) { Gitlab::Database.database_base_models_with_gitlab_shared }
    let(:databases_count) { databases.count }

    it 'cleans up any leftover indexes' do
      expect(described_class).to receive(:cleanup_leftovers!).exactly(databases_count).times

      described_class.invoke
    end

    context 'when there is an error raised' do
      it 'logs and re-raise' do
        expect(described_class).to receive(:automatic_reindexing).and_raise('Unexpected!')
        expect(Gitlab::AppLogger).to receive(:error)

        expect { described_class.invoke }.to raise_error('Unexpected!')
      end
    end

    context 'when async index creation is enabled' do
      it 'executes async index creation prior to any reindexing actions' do
        stub_feature_flags(database_async_index_creation: true)

        expect(Gitlab::Database::AsyncIndexes).to receive(:create_pending_indexes!).ordered.exactly(databases_count).times
        expect(described_class).to receive(:automatic_reindexing).ordered.exactly(databases_count).times

        described_class.invoke
      end
    end

    context 'when async index creation is disabled' do
      it 'does not execute async index creation' do
        stub_feature_flags(database_async_index_creation: false)

        expect(Gitlab::Database::AsyncIndexes).not_to receive(:create_pending_indexes!)

        described_class.invoke
      end

      it 'does not execute async index creation when disable ddl flag is enabled' do
        stub_feature_flags(disallow_database_ddl_feature_flags: true)

        expect(Gitlab::Database::AsyncIndexes).not_to receive(:create_pending_indexes!)

        described_class.invoke
      end
    end

    it 'executes async index destruction prior to any reindexing actions' do
      expect(Gitlab::Database::AsyncIndexes).to receive(:drop_pending_indexes!).ordered.exactly(databases_count).times
      expect(described_class).to receive(:automatic_reindexing).ordered.exactly(databases_count).times

      described_class.invoke
    end

    context 'calls automatic reindexing' do
      it 'uses all candidate indexes' do
        expect(described_class).to receive(:automatic_reindexing).exactly(databases_count).times

        described_class.invoke
      end

      context 'when explicit database is given' do
        it 'skips other databases' do
          expect(described_class).to receive(:automatic_reindexing).once

          described_class.invoke(Gitlab::Database::PRIMARY_DATABASE_NAME)
        end
      end
    end

    context 'when async FK validation is enabled' do
      it 'executes FK validation for each database prior to any reindexing actions' do
        expect(Gitlab::Database::AsyncConstraints).to receive(:validate_pending_entries!).ordered.exactly(databases_count).times
        expect(described_class).to receive(:automatic_reindexing).ordered.exactly(databases_count).times

        described_class.invoke
      end
    end

    context 'when async FK validation is disabled' do
      it 'does not execute FK validation' do
        stub_feature_flags(database_async_foreign_key_validation: false)

        expect(Gitlab::Database::AsyncConstraints).not_to receive(:validate_pending_entries!)

        described_class.invoke
      end

      it 'does not execute async index creation when disable ddl flag is enabled' do
        stub_feature_flags(disallow_database_ddl_feature_flags: true)

        expect(Gitlab::Database::AsyncIndexes).not_to receive(:validate_pending_entries!)

        described_class.invoke
      end
    end
  end

  describe '.automatic_reindexing' do
    subject { described_class.automatic_reindexing(maximum_records: limit) }

    let(:limit) { 5 }

    before_all do
      swapout_view_for_table(:postgres_indexes, connection: ApplicationRecord.connection)
    end

    before do
      allow(described_class).to receive(:cleanup_leftovers!)
      allow(described_class).to receive(:perform_from_queue).and_return(0)
      allow(described_class).to receive(:perform_with_heuristic).and_return(0)
    end

    it 'cleans up leftovers, before consuming the queue' do
      expect(described_class).to receive(:cleanup_leftovers!).ordered
      expect(described_class).to receive(:perform_from_queue).ordered

      subject
    end

    context 'with records in the queue' do
      before do
        create(:reindexing_queued_action)
      end

      context 'with enough records in the queue to reach limit' do
        let(:limit) { 1 }

        it 'does not perform reindexing with heuristic' do
          expect(described_class).to receive(:perform_from_queue).and_return(limit)
          expect(described_class).not_to receive(:perform_with_heuristic)

          subject
        end
      end

      context 'without enough records in the queue to reach limit' do
        let(:limit) { 2 }

        it 'continues if the queue did not have enough records' do
          expect(described_class).to receive(:perform_from_queue).ordered.and_return(1)
          expect(described_class).to receive(:perform_with_heuristic).with(maximum_records: 1).ordered

          subject
        end
      end
    end
  end

  describe '.perform_with_heuristic' do
    subject { described_class.perform_with_heuristic(candidate_indexes, maximum_records: limit) }

    let(:limit) { 2 }
    let(:coordinator) { instance_double(Gitlab::Database::Reindexing::Coordinator) }
    let(:index_selection) { instance_double(Gitlab::Database::Reindexing::IndexSelection) }
    let(:candidate_indexes) { double }
    let(:indexes) { [double, double] }

    it 'delegates to Coordinator' do
      expect(Gitlab::Database::Reindexing::IndexSelection).to receive(:new).with(candidate_indexes).and_return(index_selection)
      expect(index_selection).to receive(:take).with(limit).and_return(indexes)

      indexes.each do |index|
        expect(Gitlab::Database::Reindexing::Coordinator).to receive(:new).with(index).and_return(coordinator)
        expect(coordinator).to receive(:perform)
      end

      subject
    end
  end

  describe '.perform_from_queue' do
    subject { described_class.perform_from_queue(maximum_records: limit) }

    before_all do
      swapout_view_for_table(:postgres_indexes, connection: ApplicationRecord.connection)
    end

    let(:limit) { 2 }
    let(:queued_actions) { create_list(:reindexing_queued_action, 3) }
    let(:coordinator) { instance_double(Gitlab::Database::Reindexing::Coordinator) }

    before do
      queued_actions.take(limit).each do |action|
        allow(Gitlab::Database::Reindexing::Coordinator).to receive(:new).with(action.index).and_return(coordinator)
        allow(coordinator).to receive(:perform)
      end
    end

    it 'consumes the queue in order of created_at and applies the limit' do
      queued_actions.take(limit).each do |action|
        expect(Gitlab::Database::Reindexing::Coordinator).to receive(:new).ordered.with(action.index).and_return(coordinator)
        expect(coordinator).to receive(:perform)
      end

      subject
    end

    it 'updates queued action and sets state to done' do
      subject

      queue = queued_actions

      queue.shift(limit).each do |action|
        expect(action.reload.state).to eq('done')
      end

      queue.each do |action|
        expect(action.reload.state).to eq('queued')
      end
    end

    it 'updates queued action upon error and sets state to failed' do
      expect(Gitlab::Database::Reindexing::Coordinator).to receive(:new).ordered.with(queued_actions.first.index).and_return(coordinator)
      expect(coordinator).to receive(:perform).and_raise('something went wrong')

      subject

      states = queued_actions.map(&:reload).map(&:state)

      expect(states).to eq(%w[failed done queued])
    end
  end

  describe '.cleanup_leftovers!' do
    subject(:cleanup_leftovers) { described_class.cleanup_leftovers! }

    let(:expected_queries) do
      [
        "SET lock_timeout TO '60000ms'",
        "DROP INDEX CONCURRENTLY IF EXISTS \"public\".\"foobar_ccnew\"",
        "RESET idle_in_transaction_session_timeout; RESET lock_timeout",
        "SET lock_timeout TO '60000ms'",
        "DROP INDEX CONCURRENTLY IF EXISTS \"public\".\"foobar_ccnew1\"",
        "RESET idle_in_transaction_session_timeout; RESET lock_timeout"
      ]
    end

    let(:actual_queries) { [] }

    let(:model) { Gitlab::Database.database_base_models[Gitlab::Database::PRIMARY_DATABASE_NAME] }
    let(:connection) { model.connection }

    around do |example|
      Gitlab::Database::SharedModel.using_connection(connection) do
        example.run
      end
    end

    before do
      connection.execute(<<~SQL)
        CREATE INDEX foobar_ccnew ON users (id);
        CREATE INDEX foobar_ccnew1 ON users (id);
      SQL
    end

    it 'drops both leftover indexes' do
      allow(connection).to receive(:execute).and_wrap_original do |method, sql|
        actual_queries << sql
        method.call(sql.sub(/CONCURRENTLY/, ''))
      end

      cleanup_leftovers

      # Ordering matters here, we're making sure the query order matched what we expect.
      expect(expected_queries).to eq(actual_queries)
    end
  end
end
