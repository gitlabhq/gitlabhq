# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../tooling/quality/fixture_coverage'

RSpec.describe Quality::FixtureCoverage, feature_category: :tooling do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }

  subject(:finding) { described_class.new(%w[widgets], connection: connection).findings.first }

  # `count(column)` ignores nulls, so the adapter returns one row count plus a non-null count per
  # nullable column, keyed c0, c1, ...
  def stub_table(rows:, nullable: %w[optional_value], non_null_counts: [])
    allow(connection).to receive(:table_exists?).with('widgets').and_return(true)
    allow(connection).to receive(:quote_table_name) { |name| %("#{name}") }
    allow(connection).to receive(:quote_column_name) { |name| %("#{name}") }
    allow(connection).to receive(:columns).with('widgets').and_return(
      nullable.map { |name| double(name: name, null: true) } + [double(name: 'id', null: false)] # rubocop:disable RSpec/VerifiedDoubles -- column structs vary by adapter
    )

    counts = { 'row_count' => rows }
    non_null_counts.each_with_index { |value, index| counts["c#{index}"] = value }
    allow(connection).to receive(:select_one).and_return(counts)
  end

  describe '#findings' do
    # The caller prints a count before the findings, so dropping a table here would leave a report
    # listing fewer tables than it just announced.
    it 'reports a table that is absent from the schema rather than dropping it' do
      allow(connection).to receive(:table_exists?).with('widgets').and_return(false)

      findings = described_class.new(%w[widgets], connection: connection).findings

      expect(findings.size).to eq(1)
      expect(findings.first).to be_missing
      expect(findings.first.summary).to include('not present in this schema')
    end

    it 'reports an empty table as unseeded' do
      stub_table(rows: 0, non_null_counts: [0])

      expect(finding).to be_unseeded
      expect(finding).not_to be_single_row
      expect(finding).not_to be_no_null_variation
    end

    it 'reports a single row as thin coverage' do
      stub_table(rows: 1, non_null_counts: [1])

      expect(finding).not_to be_unseeded
      expect(finding).to be_single_row
    end

    it 'counts only nullable columns' do
      stub_table(rows: 2, nullable: %w[a b], non_null_counts: [2, 1])

      expect(finding.nullable_columns).to eq(2)
    end

    it 'flags a nullable column that never holds a null' do
      stub_table(rows: 2, non_null_counts: [2])

      expect(finding.columns_never_null).to eq(1)
      expect(finding).to be_no_null_variation
    end

    it 'does not flag a nullable column holding both a null and a value' do
      stub_table(rows: 2, non_null_counts: [1])

      expect(finding.columns_never_null).to eq(0)
      expect(finding).not_to be_no_null_variation
    end

    it 'only reports missing variation when every nullable column lacks a null' do
      stub_table(rows: 2, nullable: %w[a b], non_null_counts: [2, 1])

      expect(finding.columns_never_null).to eq(1)
      expect(finding).not_to be_no_null_variation
    end
  end

  describe 'Finding#summary' do
    it 'tells the author to add a fixture when the table is empty' do
      stub_table(rows: 0, non_null_counts: [0])

      expect(finding.summary).to include('no rows after seeding', 'db/fixtures/development/')
    end

    it 'reports the row count on its own when coverage is adequate' do
      stub_table(rows: 2, non_null_counts: [1])

      expect(finding.summary).to eq('2 row(s)')
    end

    it 'notes a single row' do
      stub_table(rows: 1, non_null_counts: [0])

      expect(finding.summary).to include('1 row(s)', 'only one row')
    end

    it 'notes missing null variation' do
      stub_table(rows: 2, non_null_counts: [2])

      expect(finding.summary).to include('2 row(s)', 'ever holds a null')
    end

    it 'combines both notes when they apply together' do
      stub_table(rows: 1, non_null_counts: [1])

      expect(finding.summary).to include('only one row', 'ever holds a null')
    end
  end
end
