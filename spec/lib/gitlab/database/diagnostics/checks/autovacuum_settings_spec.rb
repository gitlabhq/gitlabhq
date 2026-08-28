# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Checks::AutovacuumSettings, feature_category: :database do
  describe '#execute' do
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

    subject(:result) { described_class.new(connection).execute }

    before do
      allow(connection).to receive(:quote) { |value| "'#{value}'" }
      allow(connection).to receive(:select_all)
        .with(a_string_matching(/FROM pg_settings/)).and_return(settings_rows)
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
  end
end
