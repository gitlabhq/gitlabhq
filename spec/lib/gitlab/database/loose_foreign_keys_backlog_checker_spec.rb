# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LooseForeignKeysBacklogChecker, feature_category: :database do
  let(:logger) { instance_double(Gitlab::AppLogger, info: nil, warn: nil, error: nil) }

  describe '.run' do
    it 'runs the checker for every gitlab_shared connection' do
      base_model = class_double(ApplicationRecord, connection: ApplicationRecord.connection)
      instance = instance_double(described_class, run: [])

      allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared)
        .and_return({ 'main' => base_model })

      expect(described_class).to receive(:new)
        .with(base_model.connection, 'main', logger)
        .and_return(instance)

      expect(described_class.run(logger: logger)).to eq({ 'main' => [] })
    end
  end

  describe '#run' do
    let(:connection) { ApplicationRecord.connection }
    let(:checker) { described_class.new(connection, 'main', logger) }

    def create_deleted_record(model, table, primary_key_value, **attrs)
      Gitlab::Database::SharedModel.using_connection(connection) do
        model.create!(fully_qualified_table_name: table, primary_key_value: primary_key_value, **attrs)
      end
    end

    context 'when there is no backlog' do
      it 'returns an empty array' do
        expect(checker.run).to eq([])
      end
    end

    context 'with a pending backlog across multiple stores' do
      let_it_be(:project) { create(:project) }

      before do
        # Records are inserted oldest-first (so id order matches created_at order, as in production),
        # with consume_after = created_at except where a record is explicitly deferred.

        # public.projects backlog split across the cell-local table and the sharding-key table.
        create_deleted_record(LooseForeignKeys::DeletedRecord, 'public.projects', 1,
          created_at: 3.hours.ago, consume_after: 3.hours.ago)
        create_deleted_record(LooseForeignKeys::DeletedRecord, 'public.projects', 2,
          created_at: 1.hour.ago, consume_after: 1.hour.ago)
        create_deleted_record(LooseForeignKeys::ProjectDeletedRecord, 'public.projects', 3,
          project_id: project.id, created_at: 30.minutes.ago, consume_after: 30.minutes.ago)

        # A smaller, younger backlog on a different parent table, including one deferred record
        # (rescheduled into the future) that still counts as pending.
        create_deleted_record(LooseForeignKeys::DeletedRecord, 'public.users', 10,
          created_at: 15.minutes.ago, consume_after: 15.minutes.ago)
        create_deleted_record(LooseForeignKeys::DeletedRecord, 'public.users', 11,
          created_at: 10.minutes.ago, consume_after: 1.hour.from_now)
        create_deleted_record(LooseForeignKeys::DeletedRecord, 'public.users', 12,
          created_at: 5.minutes.ago, consume_after: 5.minutes.ago)

        # Processed records must be excluded from the backlog.
        create_deleted_record(LooseForeignKeys::DeletedRecord, 'public.projects', 99, status: :processed)
      end

      it 'aggregates the backlog per parent table, ordered by oldest pending age' do
        result = checker.run

        projects, users = result

        expect(result.map { |entry| entry['parent_table'] }).to eq(%w[public.projects public.users])

        expect(projects).to include(
          'parent_table' => 'public.projects',
          'pending_records' => 3,
          'capped' => false,
          'deferred_records' => 0
        )
        expect(projects['oldest_pending_age_seconds']).to be_within(120).of(3.hours.to_i)

        expect(users).to include(
          'parent_table' => 'public.users',
          'pending_records' => 3,
          'capped' => false,
          'deferred_records' => 1
        )
        expect(users['oldest_pending_age_seconds']).to be_within(120).of(15.minutes.to_i)
      end
    end

    context 'when the backlog exceeds PENDING_RECORDS_LIMIT' do
      before do
        stub_const("#{described_class}::PENDING_RECORDS_LIMIT", 2)

        # Oldest first; rows are scanned in (partition, consume_after, id) order.
        create_deleted_record(
          LooseForeignKeys::DeletedRecord, 'public.projects', 1,
          created_at: 3.hours.ago, consume_after: 3.hours.ago
        )
        create_deleted_record(
          LooseForeignKeys::DeletedRecord, 'public.projects', 2,
          created_at: 2.hours.ago, consume_after: 2.hours.ago
        )
        create_deleted_record(
          LooseForeignKeys::DeletedRecord, 'public.projects', 3,
          created_at: 1.hour.ago, consume_after: 1.hour.ago
        )
      end

      it 'clamps the count to the limit, flags it as capped, and keeps the oldest age accurate' do
        projects = checker.run.first

        expect(projects['pending_records']).to eq(2)
        expect(projects['capped']).to be(true)
        expect(projects['oldest_pending_age_seconds']).to be_within(120).of(3.hours.to_i)
      end
    end

    context 'when a parent table has fewer than MIN_PENDING_RECORDS pending rows' do
      before do
        stub_const("#{described_class}::MIN_PENDING_RECORDS", 2)

        create_deleted_record(LooseForeignKeys::DeletedRecord, 'public.projects', 1)
      end

      it 'omits the table from the results' do
        expect(checker.run).to eq([])
      end
    end

    context 'when a store scan exceeds the statement timeout' do
      before do
        allow(checker).to receive(:capped_counts).and_raise(ActiveRecord::QueryCanceled)
      end

      it 'skips the store, tracks the error, and does not fail the whole check' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(ActiveRecord::QueryCanceled), hash_including(:database, :store))
          .at_least(:once)

        expect(checker.run).to eq([])
      end
    end

    context 'when the oldest-age lookup exceeds the statement timeout' do
      before do
        # The count succeeds and reports a backlog for public.projects...
        allow(checker).to receive(:capped_counts).and_return([['public.projects', 3, 0]], [], [], [], [])
        # ...but the head-of-queue created_at lookup times out.
        allow(LooseForeignKeys::DeletedRecord).to receive(:status_pending).and_raise(ActiveRecord::QueryCanceled)
      end

      it 'reports the table with an unknown (zero) age, tracks the error, and does not fail' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(ActiveRecord::QueryCanceled), hash_including(parent_table: 'public.projects'))

        projects = checker.run.first

        expect(projects).to include('parent_table' => 'public.projects', 'pending_records' => 3,
          'oldest_pending_age_seconds' => 0)
      end
    end
  end
end
