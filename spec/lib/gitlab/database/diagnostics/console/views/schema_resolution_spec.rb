# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Console::Views::SchemaResolution, feature_category: :database do
  let(:buffer) { StringIO.new }
  let(:printer) { Gitlab::Database::Diagnostics::Console::Printer.new(output: buffer) }

  let(:schemas) do
    [
      { name: 'public', current: true, owner: 'gitlab', has_tables: true },
      { name: 'gitlab_partitions_static', current: false, owner: 'gitlab', has_tables: true }
    ]
  end

  let(:findings) { [] }
  let(:severity) { nil }
  let(:counts) { {} }

  let(:payload) do
    {
      current_user: 'gitlab',
      search_path: '"$user", public',
      schemas: schemas,
      findings: findings,
      severity: severity,
      counts: counts,
      vacuums: []
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
    it { expect(described_class.title).to eq('Search path') }
  end

  describe '#run' do
    context 'with no findings' do
      it 'reports the database as clean and counts nothing', :aggregate_failures do
        expect(view.run).to eq({})

        expect(rendered).to eq([
          '',
          '== Search path ==',
          '',
          'main ... OK',
          '   Current user: gitlab',
          '   Search path:  "$user", public',
          '',
          '   Schemas',
          '   SCHEMA                    OWNER   CURRENT',
          '   ------------------------  ------  -------',
          '   public                    gitlab  yes',
          '   gitlab_partitions_static  gitlab'
        ])
      end
    end

    context 'with findings' do
      let(:severity) { 'error' }
      let(:counts) { { 'error' => 1, 'warning' => 1 } }

      let(:findings) do
        [
          { severity: 'error', code: 'split_objects', message: 'Split objects.' },
          { severity: 'warning', code: 'partition_schema', message: 'Partition schema.' }
        ]
      end

      it 'renders the severity and counts the check supplied', :aggregate_failures do
        expect(view.run).to eq({ 'error' => 1, 'warning' => 1 })

        expect(rendered).to include('main ... 1 error, 1 warning')
      end

      it 'renders findings in the order supplied' do
        view.run

        expect(rendered.grep(/^   \[/)).to eq([
          '   [error]   Split objects.',
          '   [warning] Partition schema.'
        ])
      end

      context 'when the check supplied warnings before errors' do
        let(:findings) do
          [
            { severity: 'warning', code: 'partition_schema', message: 'Partition schema.' },
            { severity: 'error', code: 'split_objects', message: 'Split objects.' }
          ]
        end

        it 'does not reorder them' do
          view.run

          expect(rendered.grep(/^   \[/)).to eq([
            '   [warning] Partition schema.',
            '   [error]   Split objects.'
          ])
        end
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
