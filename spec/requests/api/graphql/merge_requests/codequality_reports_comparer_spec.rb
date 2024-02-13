# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.mergeRequest.codequalityReportsComparer', feature_category: :code_quality do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, :with_codequality_reports, source_project: project) }

  let(:mock_report) do
    {
      status: :parsed,
      data: {
        status: 'failed',
        new_errors: [
          {
            description: "Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.",
            fingerprint: "15cdb5c53afd42bc22f8ca366a08d547",
            severity: "major",
            file_path: "foo.rb",
            line: 10,
            engine_name: "structure"
          },
          {
            description: "Method `backwards_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.",
            fingerprint: "f3bdc1e8c102ba5fbd9e7f6cda51c95e",
            severity: "major",
            file_path: "foo.rb",
            line: 14,
            engine_name: "structure"
          },
          {
            description: "Avoid parameter lists longer than 5 parameters. [12/5]",
            fingerprint: "ab5f8b935886b942d621399f5a2ca16e",
            severity: "minor",
            file_path: "foo.rb",
            line: 14,
            engine_name: "rubocop"
          }
        ],
        resolved_errors: [],
        existing_errors: [],
        summary: {
          total: 3,
          resolved: 0,
          errored: 3
        }
      }.deep_stringify_keys
    }
  end

  let(:codequality_reports_comparer_fields) do
    <<~QUERY
      codequalityReportsComparer {
        status
        report {
          status
          newErrors {
            description
            fingerprint
            severity
            filePath
            line
            webUrl
            engineName
          }
          resolvedErrors {
            description
            fingerprint
            severity
            filePath
            line
            webUrl
            engineName
          }
          existingErrors {
            description
            fingerprint
            severity
            filePath
            line
            webUrl
            engineName
          }
          summary {
            errored
            resolved
            total
          }
        }
      }
    QUERY
  end

  let(:merge_request_fields) do
    query_graphql_field(:merge_request, { iid: merge_request.iid.to_s }, codequality_reports_comparer_fields)
  end

  let(:query) { graphql_query_for(:project, { full_path: project.full_path }, merge_request_fields) }

  subject(:result) { graphql_data_at(:project, :merge_request, :codequality_reports_comparer) }

  before do
    allow_next_found_instance_of(MergeRequest) do |merge_request|
      allow(merge_request).to receive(:compare_codequality_reports).and_return(mock_report)
    end
  end

  context 'when the user is not authorized to read the field' do
    before do
      post_graphql(query, current_user: user)
    end

    it { is_expected.to be_nil }
  end

  context 'when the user is authorized to read the field' do
    before_all do
      project.add_reporter(user)
    end

    before do
      post_graphql(query, current_user: user)
    end

    it 'returns expected data' do
      expect(result).to match(
        a_hash_including(
          {
            status: 'PARSED',
            report: {
              status: 'FAILED',
              newErrors: [
                {
                  description: 'Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.',
                  fingerprint: '15cdb5c53afd42bc22f8ca366a08d547',
                  severity: 'MAJOR',
                  filePath: 'foo.rb',
                  line: 10,
                  webUrl: nil,
                  engineName: 'structure'
                },
                {
                  description: 'Method `backwards_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.',
                  fingerprint: 'f3bdc1e8c102ba5fbd9e7f6cda51c95e',
                  severity: 'MAJOR',
                  filePath: 'foo.rb',
                  line: 14,
                  webUrl: nil,
                  engineName: 'structure'
                },
                {
                  description: 'Avoid parameter lists longer than 5 parameters. [12/5]',
                  fingerprint: 'ab5f8b935886b942d621399f5a2ca16e',
                  severity: 'MINOR',
                  filePath: 'foo.rb',
                  line: 14,
                  webUrl: nil,
                  engineName: 'rubocop'
                }
              ],
              resolvedErrors: [],
              existingErrors: [],
              summary: {
                errored: 3,
                resolved: 0,
                total: 3
              }
            }
          }.deep_stringify_keys
        )
      )
    end
  end
end
