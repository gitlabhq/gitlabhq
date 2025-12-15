# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::Requests::Issues::ServerListService, feature_category: :integrations do
  include AfterNextHelpers

  it_behaves_like 'a Jira list service', api_version: 2

  describe '#execute' do
    let_it_be(:jira_integration) { create(:jira_integration, url: 'https://jira.example.com') }

    let(:params) { {} }
    let(:integration) { described_class.new(jira_integration, params) }
    let(:response_body) { '' }
    let(:response_headers) { { 'content-type' => 'application/json' } }
    let(:expected_url_pattern) { %r{.*jira.example.com/rest/api/2/search.*} }

    subject(:result) { integration.execute }

    before do
      stub_request(:get, expected_url_pattern).to_return(status: 200, body: response_body, headers: response_headers)
    end

    context 'when the request does not return any values' do
      let(:response_body) { { issues: [] }.to_json }

      it 'returns a payload with no issues' do
        payload = result.payload

        expect(result.success?).to be_truthy
        expect(payload[:issues]).to be_empty
        expect(payload[:is_last]).to be_truthy
      end
    end

    context 'when the request returns values' do
      let(:response_body) do
        {
          total: 375,
          startAt: 0,
          issues: [{ key: 'TST-1' }, { key: 'TST-2' }]
        }.to_json
      end

      it 'returns a payload with jira issues' do
        payload = result.payload

        expect(result.success?).to be_truthy
        expect(payload[:issues].map(&:key)).to eq(%w[TST-1 TST-2])
        expect(payload[:is_last]).to be_falsy
        expect(payload[:total_count]).to eq(375)
      end
    end

    context 'when using pagination parameters' do
      let(:params) { { page: 3, per_page: 20 } }

      it 'honors page and per_page' do
        expect_next(JIRA::Client).to receive(:get)
          .with(include('startAt=40'))
          .with(include('maxResults=20'))
          .and_return({ 'issues' => [] })

        result
      end
    end

    context 'without pagination parameters' do
      let(:params) { {} }

      it 'uses the default options' do
        expect_next(JIRA::Client).to receive(:get)
          .with(include('startAt=0'))
          .with(include('maxResults=100'))
          .and_return({ 'issues' => [] })

        result
      end
    end
  end
end
