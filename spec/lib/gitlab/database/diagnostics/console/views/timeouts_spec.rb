# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Console::Views::Timeouts, feature_category: :database do
  let(:buffer) { StringIO.new }
  let(:printer) { Gitlab::Database::Diagnostics::Console::Printer.new(output: buffer) }

  let(:settings) do
    {
      'statement_timeout' => {
        value: 120_000, default_value: 0, unit: 'ms', source: 'session', source_location: nil
      },
      'lock_timeout' => {
        value: 0, default_value: 0, unit: 'ms', source: 'default', source_location: nil
      }
    }
  end

  let(:overrides) { [] }
  let(:findings) { [] }
  let(:severity) { nil }
  let(:counts) { {} }

  let(:timeouts) do
    {
      settings: settings,
      overrides: overrides,
      findings: findings,
      severity: severity,
      counts: counts
    }
  end

  let(:payload) { { timeouts: timeouts } }

  subject(:view) { described_class.new(databases: { 'main' => payload }, printer: printer) }

  before do
    Rainbow.enabled = false
  end

  def rendered
    buffer.string.split("\n")
  end

  describe '.title' do
    it { expect(described_class.title).to eq('Timeouts') }
  end

  describe '#run' do
    context 'with no findings' do
      it 'reports the database as clean and counts nothing', :aggregate_failures do
        expect(view.run).to eq({})

        expect(rendered).to eq([
          '',
          '== Timeouts ==',
          '',
          'main ... OK',
          '   Effective settings',
          '   SETTING            SESSION    CLUSTER DEFAULT  SOURCE',
          '   -----------------  ---------  ---------------  -------',
          '   statement_timeout  120000 ms  unlimited        session',
          '   lock_timeout       unlimited  unlimited        default'
        ])
      end
    end

    context 'when a setting comes from a configuration file' do
      let(:settings) do
        {
          'statement_timeout' => {
            value: 60_000, default_value: 60_000, unit: 'ms', source: 'configuration file',
            source_location: '/etc/postgresql/postgresql.conf:750'
          }
        }
      end

      it 'renders the file and line next to the source' do
        view.run

        expect(buffer.string).to include('configuration file (/etc/postgresql/postgresql.conf:750)')
      end
    end

    context 'with role and database defaults' do
      let(:overrides) do
        [
          { database_name: nil, role_name: nil, name: 'statement_timeout', value: '90s' },
          { database_name: 'gitlabhq', role_name: 'gitlab', name: 'lock_timeout', value: '5s' }
        ]
      end

      it 'renders a second table, marking a missing role or database as "(all)"' do
        view.run

        expect(rendered).to include(
          '   Role and database defaults',
          '   ROLE    DATABASE  SETTING            VALUE',
          '   ------  --------  -----------------  -----',
          '   (all)   (all)     statement_timeout  90s',
          '   gitlab  gitlabhq  lock_timeout       5s'
        )
      end
    end

    context 'without role or database defaults' do
      it 'omits the second table' do
        view.run

        expect(buffer.string).not_to include('Role and database defaults')
      end
    end

    context 'with findings' do
      let(:severity) { 'error' }
      let(:counts) { { 'error' => 1 } }

      let(:findings) do
        [{ severity: 'error', code: 'statement_timeout_unlimited', message: 'No limit.' }]
      end

      it 'renders the severity and counts the check supplied', :aggregate_failures do
        expect(view.run).to eq({ 'error' => 1 })

        expect(rendered).to include('main ... 1 error', '   [error]   No limit.')
      end

      it 'renders findings in the order supplied' do
        view.run

        expect(rendered.grep(/^   \[/)).to eq(['   [error]   No limit.'])
      end
    end

    context 'when no settings could be read' do
      let(:settings) { {} }

      it 'reports the database without a settings table', :aggregate_failures do
        expect(view.run).to eq({})

        expect(rendered).to include('main ... OK')
        expect(buffer.string).not_to include('Effective settings')
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
