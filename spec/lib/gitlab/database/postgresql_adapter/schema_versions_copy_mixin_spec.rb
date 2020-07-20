# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlAdapter::SchemaVersionsCopyMixin do
  let(:schema_migration) { double('schem_migration', table_name: table_name, all_versions: versions) }
  let(:versions) { %w(5 2 1000 200 4 93 2) }
  let(:table_name) { "schema_migrations" }

  let(:instance) do
    Object.new.extend(described_class)
  end

  before do
    allow(instance).to receive(:schema_migration).and_return(schema_migration)
    allow(instance).to receive(:quote_table_name).with(table_name).and_return("\"#{table_name}\"")
  end

  subject { instance.dump_schema_information }

  it 'uses COPY FROM STDIN' do
    expect(subject.split("\n").first).to match(/COPY "schema_migrations" \(version\) FROM STDIN;/)
  end

  it 'contains a sorted list of versions by their numeric value' do
    version_lines = subject.split("\n")[1..-2].map(&:to_i)

    expect(version_lines).to eq(versions.map(&:to_i).sort)
  end

  it 'contains a end-of-data marker' do
    expect(subject).to end_with("\\.\n")
  end

  context 'with non-Integer versions' do
    let(:versions) { %w(5 2 4 abc) }

    it 'raises an error' do
      expect { subject }.to raise_error(/invalid value for Integer/)
    end
  end
end
