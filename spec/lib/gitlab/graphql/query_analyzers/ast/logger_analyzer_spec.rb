# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::QueryAnalyzers::AST::LoggerAnalyzer do
  let(:query) { GraphQL::Query.new(GitlabSchema, document: document, context: {}, variables: { body: 'some note' }) }
  let(:document) do
    GraphQL.parse <<-GRAPHQL
      mutation createNote($body: String!) {
        createNote(input: {noteableId: "gid://gitlab/Noteable/1", body: $body}) {
          note {
            id
          }
        }
      }
    GRAPHQL
  end

  describe '#result' do
    let(:monotonic_time_before) { 42 }
    let(:monotonic_time_after) { 500 }
    let(:monotonic_time_duration) { monotonic_time_after - monotonic_time_before }

    before do
      RequestStore.store[:graphql_logs] = nil

      allow(Gitlab::Metrics::System).to receive(:monotonic_time)
        .and_return(monotonic_time_before, monotonic_time_before,
                    monotonic_time_before, monotonic_time_before,
                    monotonic_time_after)
    end

    it 'returns the complexity, depth, duration, etc' do
      results = GraphQL::Analysis::AST.analyze_query(query, [described_class], multiplex_analyzers: [])
      result = results.first

      expect(result[:duration_s]).to eq monotonic_time_duration
      expect(result[:depth]).to eq 3
      expect(result[:complexity]).to eq 3
      expect(result[:used_fields]).to eq ['Note.id', 'CreateNotePayload.note', 'Mutation.createNote']
      expect(result[:used_deprecated_fields]).to eq []
      expect(result[:used_deprecated_arguments]).to eq []

      request = result.except(:duration_s).merge({
        operation_name: 'createNote',
        variables: { body: "[FILTERED]" }.to_s
      })

      expect(RequestStore.store[:graphql_logs]).to match([request])
    end
  end
end
