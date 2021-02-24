# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer do
  subject { described_class.new }

  describe '#initial_value' do
    it 'filters out sensitive variables' do
      doc = GraphQL.parse <<-GRAPHQL
        mutation createNote($body: String!) {
          createNote(input: {noteableId: "1", body: $body}) {
            note {
              id
            }
          }
        }
      GRAPHQL

      query = GraphQL::Query.new(GitlabSchema, document: doc, context: {}, variables: { body: "some note" })

      expect(subject.initial_value(query)[:variables]).to eq('{:body=>"[FILTERED]"}')
    end
  end

  describe '#final_value' do
    let(:monotonic_time_before) { 42 }
    let(:monotonic_time_after) { 500 }
    let(:monotonic_time_duration) { monotonic_time_after - monotonic_time_before }

    it 'returns a duration in seconds' do
      allow(GraphQL::Analysis).to receive(:analyze_query).and_return([4, 2, [[], []]])
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(monotonic_time_before, monotonic_time_after)
      allow(Gitlab::GraphqlLogger).to receive(:info)

      expected_duration = monotonic_time_duration
      memo = subject.initial_value(spy('query'))

      subject.final_value(memo)

      expect(memo).to have_key(:duration_s)
      expect(memo[:duration_s]).to eq(expected_duration)
    end
  end
end
