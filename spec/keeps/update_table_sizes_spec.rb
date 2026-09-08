# frozen_string_literal: true

require 'spec_helper'
require './keeps/update_table_sizes'

RSpec.describe Keeps::UpdateTableSizes, feature_category: :database do
  subject(:keep) { described_class.new }

  let(:postgres_ai) { instance_double(Keeps::Helpers::PostgresAi) }
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:base_model) { class_double(ApplicationRecord, connection: connection) }

  let(:entries) do
    [
      dictionary_entry('write_locked_table', 'large'),
      dictionary_entry('truncated_table', 'large'),
      dictionary_entry('missing_table', 'medium'),
      dictionary_entry('unchanged_table', 'medium'),
      dictionary_entry('internal_table', 'medium', gitlab_schema: 'gitlab_internal')
    ]
  end

  before do
    allow(Keeps::Helpers::PostgresAi).to receive(:new).and_return(postgres_ai)
    allow(Gitlab::Database::Dictionary).to receive(:entries).and_return(entries)
    allow(Gitlab::Database).to receive(:schemas_to_base_models).and_return(
      'gitlab_main' => [base_model],
      'gitlab_internal' => [base_model]
    )

    allow(postgres_ai).to receive(:table_write_locked?).and_return(false)
    allow(postgres_ai).to receive(:table_write_locked?).with('write_locked_table').and_return(true)

    allow(postgres_ai).to receive(:fetch_postgres_table_size)
      .with('truncated_table').and_return([{ 'size_in_bytes' => 65536, 'classification' => 'small' }])
    allow(postgres_ai).to receive(:fetch_postgres_table_size)
      .with('missing_table').and_return([])
    allow(postgres_ai).to receive(:fetch_postgres_table_size)
      .with('unchanged_table').and_return([{ 'size_in_bytes' => 20 * (1024**3), 'classification' => 'medium' }])
    allow(postgres_ai).to receive(:fetch_postgres_table_size)
      .with('internal_table').and_return([{ 'size_in_bytes' => 65536, 'classification' => 'small' }])
  end

  def dictionary_entry(table_name, table_size, gitlab_schema: 'gitlab_main')
    instance_double(
      Gitlab::Database::Dictionary::Entry,
      table_name: table_name,
      table_size: table_size,
      gitlab_schema: gitlab_schema
    )
  end

  describe '#each_identified_change' do
    it 'reclassifies genuinely empty tables and skips write-locked, missing and internal ones' do
      changes = []
      keep.each_identified_change { |change| changes << change }

      expect(changes.size).to eq(1)
      expect(changes.first.context[:tables_to_update]).to eq('truncated_table' => 'small')
    end

    it 'does not query the size of write-locked tables' do
      keep.each_identified_change { |change| change }

      expect(postgres_ai).not_to have_received(:fetch_postgres_table_size).with('write_locked_table')
    end

    context 'when no table classification changed' do
      let(:entries) { [dictionary_entry('unchanged_table', 'medium')] }

      it 'yields no change' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end
  end

  describe '#make_change!' do
    let(:rubocop_config) do
      {
        'Migration/UpdateLargeTable' => {
          'OverLimitTables' => [:huge_table],
          'LargeTables' => [:other_table, :truncated_table]
        }
      }
    end

    before do
      allow(Keeps::Helpers::ReviewerRoulette).to receive(:instance)
        .and_return(instance_double(Keeps::Helpers::ReviewerRoulette, random_reviewer_for: 'reviewer'))

      allow(YAML).to receive(:safe_load_file).and_call_original
      allow(YAML).to receive(:safe_load_file)
        .with('db/docs/truncated_table.yml')
        .and_return({ 'table_name' => 'truncated_table', 'table_size' => 'large' })
      allow(YAML).to receive(:load_file).and_call_original
      allow(YAML).to receive(:load_file).with(described_class::RUBOCOP_PATH).and_return(rubocop_config)
      allow(File).to receive(:write)
    end

    it 'demotes the table in the dictionary and removes it from rubocop-migrations.yml' do
      change = nil
      keep.each_identified_change { |identified| change = keep.make_change!(identified) }

      expect(File).to have_received(:write)
        .with('db/docs/truncated_table.yml', include('table_size: small'))
      expect(File).to have_received(:write)
        .with(described_class::RUBOCOP_PATH, include('- :other_table').and(exclude(':truncated_table')))
      expect(change.changed_files).to contain_exactly('db/docs/truncated_table.yml', described_class::RUBOCOP_PATH)
    end
  end
end
