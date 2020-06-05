# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::SchemaCleaner do
  let(:example_schema) { fixture_file(File.join('gitlab', 'database', 'structure_example.sql')) }
  let(:io) { StringIO.new }

  subject do
    described_class.new(example_schema).clean(io)
    io.string
  end

  it 'removes comments on extensions' do
    expect(subject).not_to include('COMMENT ON EXTENSION')
  end

  it 'sets the search_path' do
    expect(subject.split("\n").first).to eq('SET search_path=public;')
  end

  it 'cleans up the full schema as expected (blackbox test with example)' do
    expected_schema = fixture_file(File.join('gitlab', 'database', 'structure_example_cleaned.sql'))

    expect(subject).to eq(expected_schema)
  end
end
