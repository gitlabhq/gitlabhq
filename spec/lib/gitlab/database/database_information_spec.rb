# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DatabaseInformation, feature_category: :database do
  describe '.execute' do
    subject(:result) { described_class.execute }

    it 'returns a snapshot for the main database by default', :aggregate_failures do
      expect(result[:databases]).to have_key('main')

      payload = result[:databases]['main']
      expect(payload[:current_user]).to be_a(String).and(be_present)
      expect(payload[:search_path]).to be_a(String).and(be_present)
      expect(payload[:schemas]).to be_an(Array).and(be_present)
    end

    it 'embeds the verdict the search path check reached', :aggregate_failures do
      payload = result[:databases]['main']

      expect(payload).to include(:severity, :counts)
      expect(payload[:findings]).to be_an(Array)
    end

    it 'merges the check result with the vacuum and autovacuum snapshots', :aggregate_failures do
      check_result = { search_path: 'public', findings: [], severity: nil, counts: {} }

      expect_next_instance_of(Gitlab::Database::Diagnostics::Checks::SchemaResolution) do |check|
        expect(check).to receive(:execute).and_return(check_result)
      end

      payload = result[:databases]['main']

      expect(payload).to include(check_result)
      expect(payload[:vacuums]).to eq([])
      expect(payload[:autovacuum_config]).to include(:settings)
    end

    context 'with vacuum progress' do
      let(:connection) { Gitlab::Database.database_base_models['main'].connection }
      let(:database_version) { 17_00_04 }
      let(:vacuum_rows) do
        [
          {
            'pid' => '4242',
            'schema_name' => 'public',
            'table_name' => 'ci_builds',
            'phase' => 'vacuuming indexes',
            'heap_blks_total' => '1000',
            'heap_blks_scanned' => '600',
            'heap_blks_vacuumed' => '500',
            'index_vacuum_count' => '2',
            'max_dead_tuple_bytes' => '2097152',
            'dead_tuple_bytes' => '2000000',
            'indexes_total' => '5',
            'indexes_processed' => '3',
            'backend_type' => 'autovacuum worker',
            'activity_query' => 'autovacuum: VACUUM public.ci_builds',
            'running_time_seconds' => '36000',
            'delay_time' => '12.5'
          }
        ]
      end

      subject(:vacuums) { described_class.execute[:databases]['main'][:vacuums] }

      before do
        allow(connection).to receive(:database_version).and_return(database_version)
        allow(connection).to receive(:select_all).and_call_original
        allow(connection).to receive(:select_all)
          .with(a_string_matching(/pg_stat_progress_vacuum/)).and_return(vacuum_rows)

        # Keep this context focused on vacuum progress: stub the sibling
        # autovacuum-config collection so its queries don't hit the real DB.
        allow_next_instance_of(described_class) do |info|
          allow(info).to receive(:collect_autovacuum_config).and_return({})
        end
      end

      it 'maps each in-progress vacuum into a typed hash', :aggregate_failures do
        expect(vacuums.size).to eq(1)

        expect(vacuums.first).to include(
          pid: 4242,
          schema_name: 'public',
          table_name: 'ci_builds',
          phase: 'vacuuming indexes',
          heap_blks_total: 1000,
          heap_blks_scanned: 600,
          heap_blks_vacuumed: 500,
          index_vacuum_count: 2,
          max_dead_tuple_bytes: 2097152,
          dead_tuple_bytes: 2000000,
          indexes_total: 5,
          indexes_processed: 3,
          vacuum_type: 'autovacuum',
          anti_wraparound: false,
          running_time_seconds: 36000
        )
      end

      context 'when the vacuum is a manually issued VACUUM' do
        let(:vacuum_rows) do
          [{ 'pid' => '4242', 'backend_type' => 'client backend', 'activity_query' => 'VACUUM ci_builds' }]
        end

        it 'classifies it as manual' do
          expect(vacuums.first).to include(vacuum_type: 'manual', anti_wraparound: false)
        end
      end

      context 'when the vacuum is an anti-wraparound autovacuum' do
        let(:vacuum_rows) do
          [{
            'pid' => '4242',
            'backend_type' => 'autovacuum worker',
            'activity_query' => 'autovacuum: VACUUM public.ci_builds (to prevent wraparound)'
          }]
        end

        it 'flags it as anti-wraparound' do
          expect(vacuums.first).to include(vacuum_type: 'autovacuum', anti_wraparound: true)
        end
      end

      it 'returns an empty array when no vacuum is running' do
        allow(connection).to receive(:select_all)
          .with(a_string_matching(/pg_stat_progress_vacuum/)).and_return([])

        expect(vacuums).to eq([])
      end

      context 'on PostgreSQL 18 and newer' do
        let(:database_version) { 18_00_00 }

        it 'selects and casts delay_time', :aggregate_failures do
          expect(vacuums.first[:delay_time]).to eq(12.5)
          expect(connection).to have_received(:select_all).with(a_string_matching(/v\.delay_time/))
        end
      end

      context 'on PostgreSQL 17' do
        let(:database_version) { 17_00_04 }
        let(:vacuum_rows) do
          [{ 'pid' => '4242', 'phase' => 'scanning heap', 'index_vacuum_count' => '0' }]
        end

        it 'omits the delay_time column and reports nil', :aggregate_failures do
          expect(vacuums.first[:delay_time]).to be_nil
          expect(connection).not_to have_received(:select_all).with(a_string_matching(/v\.delay_time/))
        end
      end

      context 'on PostgreSQL 16' do
        let(:database_version) { 16_00_10 }

        it 'skips vacuum collection without running the query', :aggregate_failures do
          expect(vacuums).to eq([])
          expect(connection).not_to have_received(:select_all)
            .with(a_string_matching(/pg_stat_progress_vacuum/))
        end
      end
    end

    context 'with autovacuum configuration' do
      let(:connection) { Gitlab::Database.database_base_models['main'].connection }
      let(:settings_rows) do
        # Deliberately out of AUTOVACUUM_SETTING_NAMES order, to prove the
        # collector re-orders rather than relying on the SQL row order.
        [
          { 'name' => 'maintenance_work_mem', 'setting' => '65536', 'unit' => 'kB' },
          { 'name' => 'autovacuum', 'setting' => 'on', 'unit' => nil },
          { 'name' => 'autovacuum_max_workers', 'setting' => '3', 'unit' => nil }
        ]
      end

      subject(:config) { described_class.execute[:databases]['main'][:autovacuum_config] }

      before do
        allow(connection).to receive(:select_all).and_call_original
        allow(connection).to receive(:select_all)
          .with(a_string_matching(/FROM pg_settings/)).and_return(settings_rows)

        # Keep this context focused on autovacuum config: stub the sibling
        # vacuum-progress collection so its query doesn't hit the real DB.
        allow_next_instance_of(described_class) do |info|
          allow(info).to receive(:collect_vacuums).and_return([])
        end
      end

      it 'maps effective settings into a name-keyed hash with value and unit' do
        expect(config[:settings]).to eq(
          'autovacuum' => { value: 'on', unit: nil },
          'autovacuum_max_workers' => { value: '3', unit: nil },
          'maintenance_work_mem' => { value: '65536', unit: 'kB' }
        )
      end

      it 'orders settings to match AUTOVACUUM_SETTING_NAMES regardless of SQL row order' do
        expect(config[:settings].keys).to eq(%w[autovacuum autovacuum_max_workers maintenance_work_mem])
      end
    end

    context 'when a database name does not map to a known model' do
      subject(:result) { described_class.execute(database_names: %w[bogus]) }

      it 'returns an error payload for that database' do
        expect(result[:databases]['bogus']).to eq(error: 'Unknown database: bogus')
      end
    end

    context 'when the connection raises an error' do
      let(:failing_model) { class_double(ApplicationRecord) }
      let(:error) { StandardError.new('PG::ConnectionBad: could not connect to host db.internal:5432') }

      before do
        allow(Gitlab::Database).to receive(:database_base_models)
          .and_return({ 'main' => failing_model })
        allow(failing_model).to receive(:connection).and_raise(error)
      end

      it 'returns a sanitized error payload and tracks the exception', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error, database_name: 'main')

        expect(result[:databases]['main']).to eq(error: 'Failed to gather information for database: main')
      end
    end
  end
end
