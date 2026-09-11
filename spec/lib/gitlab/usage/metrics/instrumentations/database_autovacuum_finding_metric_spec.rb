# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DatabaseAutovacuumFindingMetric,
  feature_category: :database do
  let(:check_class) { Gitlab::Database::Diagnostics::Checks::AutovacuumSettings }

  describe '#value' do
    before do
      check = instance_double(check_class, execute: { findings: [{ code: 'autovacuum_disabled' }] })

      allow(check_class).to receive(:new).and_return(check)
    end

    context 'when the check reports the requested code' do
      it_behaves_like 'a correct instrumented metric value',
        { time_frame: 'none', options: { finding_code: 'autovacuum_disabled' } } do
        let(:expected_value) { true }
      end
    end

    context 'when the check does not report the requested code' do
      it_behaves_like 'a correct instrumented metric value',
        { time_frame: 'none', options: { finding_code: 'autovacuum_work_mem_inherited' } } do
        let(:expected_value) { false }
      end
    end

    context 'when the check fails' do
      before do
        allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(false)
        allow(check_class).to receive(:new).and_raise(ActiveRecord::StatementInvalid)
      end

      # The fallback must stay distinct from false, so a failed read is not
      # counted as an instance with no finding.
      it 'reports the fallback instead of false' do
        metric = described_class.new(time_frame: 'none', options: { finding_code: 'autovacuum_disabled' })

        expect(metric.value).to eq(described_class::FALLBACK)
      end
    end
  end

  describe 'the finding_code option' do
    it 'rejects a finding code the check cannot emit' do
      expect { described_class.new(time_frame: 'none', options: { finding_code: 'not_a_real_code' }) }
        .to raise_error(ArgumentError, /must be one of/)
    end
  end

  describe 'FINDING_CODES' do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

    # Values that trip every heuristic at once.
    let(:settings_rows) do
      {
        'autovacuum' => 'off',
        'autovacuum_max_workers' => '1',
        'autovacuum_vacuum_cost_delay' => '0',
        'autovacuum_vacuum_cost_limit' => '-1',
        'vacuum_cost_limit' => '200',
        'autovacuum_work_mem' => '-1'
      }.map { |name, setting| { 'name' => name, 'setting' => setting, 'unit' => nil } }
    end

    before do
      allow(connection).to receive(:quote) { |value| "'#{value}'" }
      allow(connection).to receive(:select_all).and_return(settings_rows)
    end

    it 'matches the codes the check emits' do
      findings = check_class.new(connection).execute[:findings]

      expect(findings.pluck(:code)).to match_array(described_class::FINDING_CODES)
    end
  end
end
