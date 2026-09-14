# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Checks::AutovacuumSettings, feature_category: :database do
  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

    # Healthy values; contexts below override individual settings.
    let(:defaults) do
      {
        'autovacuum' => ['on', nil],
        'autovacuum_max_workers' => ['6', nil],
        'autovacuum_vacuum_cost_delay' => %w[2 ms],
        'autovacuum_vacuum_cost_limit' => ['1000', nil],
        'vacuum_cost_limit' => ['200', nil],
        'autovacuum_work_mem' => %w[1048576 kB],
        'maintenance_work_mem' => %w[65536 kB]
      }
    end

    let(:overrides) { {} }

    # Deliberately reversed, to prove the check re-orders rather than relying
    # on the SQL row order.
    let(:settings_rows) do
      defaults.merge(overrides).map do |name, (setting, unit)|
        { 'name' => name, 'setting' => setting, 'unit' => unit }
      end.reverse
    end

    let(:override_rows) { [] }
    let(:largest_table_rows) { [] }

    subject(:result) { described_class.new(connection).execute }

    before do
      allow(connection).to receive(:quote) { |value| "'#{value}'" }
      allow(connection).to receive(:select_all)
        .with(a_string_matching(/FROM pg_settings/)).and_return(settings_rows)
      allow(connection).to receive(:select_all)
        .with(a_string_matching(/reloptions IS NOT NULL/)).and_return(override_rows)
      allow(connection).to receive(:select_all)
        .with(a_string_matching(/pg_catalog/)).and_return(largest_table_rows)
    end

    it 'maps effective settings into a name-keyed hash with value and unit' do
      expect(result[:settings]['autovacuum']).to eq(value: 'on', unit: nil)
      expect(result[:settings]['maintenance_work_mem']).to eq(value: '65536', unit: 'kB')
    end

    it 'orders settings to match SETTING_NAMES regardless of SQL row order' do
      expect(result[:settings].keys).to eq(described_class::SETTING_NAMES & defaults.keys)
    end

    it 'reports a healthy configuration without findings', :aggregate_failures do
      expect(result[:findings]).to be_empty
      expect(result[:severity]).to be_nil
      expect(result[:counts]).to eq({})
    end

    context 'when autovacuum is disabled' do
      let(:overrides) { { 'autovacuum' => ['off', nil] } }

      it 'reports an error tied to the autovacuum setting', :aggregate_failures do
        finding = result[:findings].first

        expect(finding).to include(severity: 'error', code: 'autovacuum_disabled', setting_name: 'autovacuum')
        expect(result[:severity]).to eq('error')
        expect(result[:counts]).to eq('error' => 1)
      end
    end

    context 'when the cost delay disables throttling' do
      let(:overrides) { { 'autovacuum_vacuum_cost_delay' => %w[0 ms] } }

      it 'reports an error tied to the cost delay setting' do
        expect(result[:findings].first).to include(
          severity: 'error',
          code: 'autovacuum_throttling_disabled',
          setting_name: 'autovacuum_vacuum_cost_delay'
        )
      end
    end

    context 'when fewer workers than the PostgreSQL default are configured' do
      let(:overrides) { { 'autovacuum_max_workers' => ['2', nil] } }

      it 'reports a warning tied to the max workers setting' do
        expect(result[:findings].first).to include(
          severity: 'warning',
          code: 'autovacuum_max_workers_low',
          setting_name: 'autovacuum_max_workers'
        )
      end
    end

    context 'when the explicit cost limit is at the conservative default' do
      let(:overrides) { { 'autovacuum_vacuum_cost_limit' => ['200', nil] } }

      it 'reports a warning without annotating an effective value', :aggregate_failures do
        expect(result[:findings].first).to include(
          severity: 'warning',
          code: 'autovacuum_cost_limit_low',
          setting_name: 'autovacuum_vacuum_cost_limit'
        )
        expect(result[:settings]['autovacuum_vacuum_cost_limit']).not_to have_key(:effective_value)
      end
    end

    context 'when the cost limit inherits a low vacuum_cost_limit' do
      let(:overrides) { { 'autovacuum_vacuum_cost_limit' => ['-1', nil] } }

      it 'judges and annotates the resolved limit', :aggregate_failures do
        expect(result[:findings].pluck(:code)).to include('autovacuum_cost_limit_low')
        expect(result[:settings]['autovacuum_vacuum_cost_limit']).to eq(
          value: '-1', unit: nil, effective_value: '200'
        )
      end
    end

    context 'when the cost limit inherits a healthy vacuum_cost_limit' do
      let(:overrides) do
        { 'autovacuum_vacuum_cost_limit' => ['-1', nil], 'vacuum_cost_limit' => ['1000', nil] }
      end

      it 'annotates the resolved limit without a finding', :aggregate_failures do
        expect(result[:findings]).to be_empty
        expect(result[:settings]['autovacuum_vacuum_cost_limit'][:effective_value]).to eq('1000')
      end
    end

    context 'when autovacuum_work_mem inherits maintenance_work_mem' do
      let(:overrides) { { 'autovacuum_work_mem' => ['-1', 'kB'] } }

      it 'reports a warning tied to the work mem setting' do
        expect(result[:findings].first).to include(
          severity: 'warning',
          code: 'autovacuum_work_mem_inherited',
          setting_name: 'autovacuum_work_mem'
        )
      end
    end

    context 'with multiple flagged settings' do
      let(:overrides) do
        {
          'autovacuum_max_workers' => ['1', nil],
          'autovacuum_vacuum_cost_delay' => %w[0 ms],
          'autovacuum_work_mem' => ['-1', 'kB']
        }
      end

      it 'sorts errors first and tallies the counts', :aggregate_failures do
        expect(result[:findings].pluck(:severity)).to eq(%w[error warning warning])
        expect(result[:severity]).to eq('error')
        expect(result[:counts]).to eq('error' => 1, 'warning' => 2)
      end
    end

    context 'when settings are absent on the running PostgreSQL version' do
      let(:settings_rows) do
        [{ 'name' => 'maintenance_work_mem', 'setting' => '65536', 'unit' => 'kB' }]
      end

      it 'skips their checks instead of misfiring', :aggregate_failures do
        expect(result[:settings].keys).to eq(%w[maintenance_work_mem])
        expect(result[:findings]).to be_empty
      end
    end

    context 'with per-table overrides' do
      let(:override_rows) do
        [
          {
            'schema_name' => 'public',
            'table_name' => 'ci_builds',
            'total_bytes' => '5368709120',
            'estimated_rows' => '1000000',
            'overrides' => '{"autovacuum_vacuum_scale_factor": "0.01"}'
          },
          {
            'schema_name' => 'public',
            'table_name' => 'audit_events',
            'total_bytes' => '1073741824',
            'estimated_rows' => '500000',
            'overrides' => '{"autovacuum_enabled": "false"}'
          }
        ]
      end

      it 'maps the rows, parsing the JSON overrides and casting numeric columns' do
        expect(result[:table_overrides].first).to eq(
          schema_name: 'public',
          table_name: 'ci_builds',
          total_bytes: 5368709120,
          estimated_rows: 1000000,
          overrides: { 'autovacuum_vacuum_scale_factor' => '0.01' },
          autovacuum_disabled: false
        )
      end

      it 'reports an error finding for the table disabling autovacuum', :aggregate_failures do
        expect(result[:table_overrides].last).to include(autovacuum_disabled: true)
        expect(result[:findings].first).to include(severity: 'error', code: 'tables_autovacuum_disabled')
        expect(result[:findings].first[:message]).to include('1 table')
        expect(result[:severity]).to eq('error')
      end

      it 'defaults overrides to an empty hash when none are returned' do
        override_rows.first['overrides'] = nil

        expect(result[:table_overrides].first[:overrides]).to eq({})
      end

      # reloptions keep the boolean as the user typed it; PostgreSQL accepts
      # all of these spellings.
      context 'when autovacuum_enabled is spelled in different ways' do
        where(:value, :disabled) do
          'false' | true
          'off'   | true
          'OFF'   | true
          '0'     | true
          'no'    | true
          'f'     | true
          'n'     | true
          'on'    | false
          'true'  | false
          'maybe' | false
        end

        with_them do
          let(:override_rows) do
            [{
              'schema_name' => 'public', 'table_name' => 't',
              'total_bytes' => '1', 'estimated_rows' => '1',
              'overrides' => %({"autovacuum_enabled": "#{value}"})
            }]
          end

          it 'recognises the spelling' do
            expect(result[:table_overrides].first).to include(autovacuum_disabled: disabled)
          end
        end
      end
    end

    context 'with a flagged setting and a table disabling autovacuum' do
      let(:overrides) { { 'autovacuum_max_workers' => ['1', nil] } }

      let(:override_rows) do
        [{
          'schema_name' => 'public', 'table_name' => 't',
          'total_bytes' => '1', 'estimated_rows' => '1',
          'overrides' => '{"autovacuum_enabled": "off"}'
        }]
      end

      it 'merges both groups into one sorted list with shared counts', :aggregate_failures do
        expect(result[:findings].pluck(:code)).to eq(%w[tables_autovacuum_disabled autovacuum_max_workers_low])
        expect(result[:severity]).to eq('error')
        expect(result[:counts]).to eq('error' => 1, 'warning' => 1)
      end
    end

    context 'with a high global scale factor' do
      let(:overrides) { { 'autovacuum_vacuum_scale_factor' => ['0.2', nil] } }

      let(:largest_table_rows) do
        [
          large_table('merge_request_diffs', nil),
          large_table('ci_builds', '{"autovacuum_vacuum_scale_factor": "0.01"}'),
          large_table('namespaces', '{"autovacuum_vacuum_scale_factor": "0.5"}'),
          large_table('users', '{"autovacuum_vacuum_threshold": "1000"}'),
          large_table('audit_events', '{"autovacuum_enabled": "false"}'),
          large_table('small_table', nil).merge('total_bytes' => '1048576')
        ]
      end

      def large_table(name, overrides)
        {
          'schema_name' => 'public', 'table_name' => name,
          'total_bytes' => '21474836480', 'estimated_rows' => '9000000',
          'overrides' => overrides
        }
      end

      it 'reports large tables whose scale factor in effect is still high', :aggregate_failures do
        expect(result[:scale_factor_risks].pluck(:table_name)).to eq(%w[merge_request_diffs namespaces users])
        expect(result[:scale_factor_risks].first).to eq(
          schema_name: 'public',
          table_name: 'merge_request_diffs',
          total_bytes: 21474836480,
          estimated_rows: 9000000
        )
        expect(result[:findings].first).to include(severity: 'warning', code: 'scale_factor_risk')
        expect(result[:findings].first[:message]).to include('3 large tables')
      end
    end

    context 'with a low global scale factor' do
      let(:overrides) { { 'autovacuum_vacuum_scale_factor' => ['0.05', nil] } }

      let(:largest_table_rows) do
        [{
          'schema_name' => 'public', 'table_name' => 'merge_request_diffs',
          'total_bytes' => '21474836480', 'estimated_rows' => '9000000',
          'overrides' => nil
        }]
      end

      it 'reports no risks without querying the largest tables', :aggregate_failures do
        expect(connection).not_to receive(:select_all).with(a_string_matching(/pg_catalog/))

        expect(result[:scale_factor_risks]).to be_empty
        expect(result[:findings]).to be_empty
      end
    end

    context 'with a table at the large-table size threshold' do
      let(:overrides) { { 'autovacuum_vacuum_scale_factor' => ['0.2', nil] } }

      where(:total_bytes, :risk_count) do
        10737418240 | 1
        10737418239 | 0
      end

      with_them do
        let(:largest_table_rows) do
          [{
            'schema_name' => 'public', 'table_name' => 't',
            'total_bytes' => total_bytes.to_s, 'estimated_rows' => '1',
            'overrides' => nil
          }]
        end

        it 'treats 10 GiB as the first size at risk' do
          expect(result[:scale_factor_risks].size).to eq(risk_count)
        end
      end
    end
  end
end
