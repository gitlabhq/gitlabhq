# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../scripts/database/query_analyzers/jsonb_scan_detector'

RSpec.describe Database::QueryAnalyzers::JSONBScanDetector, feature_category: :database do
  let(:invalid_query_string) do
    <<~SQL
      SELECT
          *
      FROM
          member_roles
      WHERE
          member_roles.permissions @> ('{"admin_merge_request":true}')::jsonb
    SQL
  end

  let(:invalid_query) { { 'query' => invalid_query_string, 'fingerprint' => '0000000000000001' } }

  let(:valid_query_string) { "SELECT * FROM users WHERE name = 'bob'" }

  let(:valid_query) { { 'query' => valid_query_string, 'fingerprint' => '0000000000000002' } }

  let(:config) { {} }

  subject(:analyzer) { described_class.new(config) }

  it "initalizes" do
    expect { analyzer }.not_to raise_error
  end

  context 'when no TODOs are defined' do
    it 'finds the invalid query' do
      [valid_query, invalid_query].each { |q| analyzer.analyze q }
      expect(analyzer.output[:bad_queries].length).to eq 1
    end
  end

  context 'when a TODO is defined' do
    let(:config) do
      {
        "todos" => [
          invalid_query['fingerprint']
        ]
      }
    end

    it 'does not find the invalid query' do
      [valid_query, invalid_query].each { |q| analyzer.analyze q }
      expect(analyzer.output[:bad_queries].length).to eq 0
    end
  end
end
