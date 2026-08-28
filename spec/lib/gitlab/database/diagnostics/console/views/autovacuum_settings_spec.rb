# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Console::Views::AutovacuumSettings, feature_category: :database do
  let(:buffer) { StringIO.new }
  let(:printer) { Gitlab::Database::Diagnostics::Console::Printer.new(output: buffer) }

  let(:settings) do
    {
      'autovacuum' => { value: 'on', unit: nil },
      'autovacuum_naptime' => { value: '60', unit: 's' },
      'autovacuum_vacuum_cost_limit' => { value: '-1', unit: nil, effective_value: '200' },
      'autovacuum_work_mem' => { value: '-1', unit: 'kB' }
    }
  end

  let(:findings) { [] }
  let(:severity) { nil }
  let(:counts) { {} }

  let(:payload) do
    {
      autovacuum_config: {
        settings: settings,
        findings: findings,
        severity: severity,
        counts: counts
      }
    }
  end

  subject(:view) { described_class.new(databases: { 'main' => payload }, printer: printer) }

  before do
    Rainbow.enabled = false
  end

  def rendered
    buffer.string.split("\n")
  end

  describe '.title' do
    it { expect(described_class.title).to eq('Autovacuum settings') }
  end

  describe '#run' do
    context 'with no findings' do
      it 'reports the database as clean and formats values with their unit', :aggregate_failures do
        expect(view.run).to eq({})

        expect(rendered).to eq([
          '',
          '== Autovacuum settings ==',
          '',
          'main ... OK',
          '   Effective settings',
          '   SETTING                       VALUE',
          '   ----------------------------  -------------------',
          '   autovacuum                    on',
          '   autovacuum_naptime            60 s',
          '   autovacuum_vacuum_cost_limit  -1 (effective: 200)',
          '   autovacuum_work_mem           -1'
        ])
      end
    end

    context 'with findings' do
      let(:severity) { 'error' }
      let(:counts) { { 'error' => 1, 'warning' => 1 } }

      let(:findings) do
        [
          { severity: 'error', code: 'autovacuum_disabled', message: 'Autovacuum is disabled.' },
          { severity: 'warning', code: 'autovacuum_work_mem_inherited', message: 'Work mem inherited.' }
        ]
      end

      it 'renders the severity and counts the check supplied', :aggregate_failures do
        expect(view.run).to eq({ 'error' => 1, 'warning' => 1 })

        expect(rendered).to include('main ... 1 error, 1 warning')
        expect(rendered.grep(/^   \[/)).to eq([
          '   [error]   Autovacuum is disabled.',
          '   [warning] Work mem inherited.'
        ])
      end
    end

    context 'when no settings could be read' do
      let(:settings) { {} }

      it 'explains instead of rendering an empty table', :aggregate_failures do
        view.run

        expect(buffer.string).to include('No autovacuum settings could be read.')
        expect(buffer.string).not_to include('SETTING')
      end
    end

    context 'when the collector could not read the database' do
      let(:payload) { { error: 'Failed to gather information for database: main' } }

      it 'counts an error and points at the logs for the cause', :aggregate_failures do
        expect(view.run).to eq({ 'error' => 1 })

        expect(rendered).to include(
          'main ... unavailable',
          '   Failed to gather information for database: main'
        )
        expect(buffer.string).to include('sent to the exception tracker')
      end
    end
  end
end
