# frozen_string_literal: true

RSpec.shared_examples 'query without source filters' do
  it do
    expect(subject.where_values_hash.keys).not_to include('source_id', 'source_type')
  end
end

RSpec.shared_examples 'query with source filters' do
  it do
    expect(subject.where_values_hash.keys).to include('source_id', 'source_type')
  end
end
