# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer do
  let(:initial_value) { analyzer.initial_value(query) }
  let(:analyzer) { described_class.new }
  let(:query) { GraphQL::Query.new(GitlabSchema, document: document, context: {}, variables: { body: "some note" }) }
  let(:document) do
    GraphQL.parse <<-GRAPHQL
      mutation createNote($body: String!) {
        createNote(input: {noteableId: "1", body: $body}) {
          note {
            id
          }
        }
      }
    GRAPHQL
  end

  describe 'variables' do
    subject { initial_value.fetch(:variables) }

    it { is_expected.to eq('{:body=>"[FILTERED]"}') }
  end

  describe '#final_value' do
    let(:monotonic_time_before) { 42 }
    let(:monotonic_time_after) { 500 }
    let(:monotonic_time_duration) { monotonic_time_after - monotonic_time_before }
    let(:memo) { initial_value }

    subject(:final_value) { analyzer.final_value(memo) }

    before do
      RequestStore.store[:graphql_logs] = nil

      allow(GraphQL::Analysis).to receive(:analyze_query).and_return([4, 2, [[], []]])
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(monotonic_time_before, monotonic_time_after)
      allow(Gitlab::GraphqlLogger).to receive(:info)
    end

    it 'inserts duration in seconds to memo and sets request store' do
      expect { final_value }.to change { memo[:duration_s] }.to(monotonic_time_duration)
                            .and change { RequestStore.store[:graphql_logs] }.to([memo])
    end
  end
end
