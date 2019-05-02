# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer do

  subject { described_class.new }
  let(:query_string) { "abc" }
  let(:provided_variables) { { a: 1, b: 2, c: 3 } }
  let(:complexity) { 4 }
  let(:depth) { 2 }
  let(:expected_hash) do
    { query_string: query_string,
      variables: provided_variables,
      complexity: complexity,
      depth: depth }
  end

  it 'assembles a hash' do
    query = OpenStruct.new(query_string: query_string, provided_variables: provided_variables)

    subject.initial_value(query)

    expect(subject.instance_variable_get("@info_hash")).to eq expected_hash
  end

end
