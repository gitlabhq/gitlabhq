# frozen_string_literal: true

RSpec.shared_examples 'a Jira list service' do |api_version:|
  let(:jira_integration) { create(:jira_integration) }
  let(:params) { {} }
  let(:integration) { described_class.new(jira_integration, params) }

  subject(:result) { integration.execute }

  context 'without jira_integration' do
    before do
      jira_integration.update!(active: false)
    end

    it 'returns an error response' do
      expect(result.error?).to be_truthy
      expect(result.message).to eq('Jira service not configured.')
    end
  end

  context 'when jira_integration is nil' do
    let(:jira_integration) { nil }

    it 'returns an error response' do
      expect(result.error?).to be_truthy
      expect(result.message).to eq('Jira service not configured.')
    end
  end

  context 'with jira_integration' do
    context 'when validations and params are ok' do
      let(:jira_integration) { create(:jira_integration, url: 'https://jira.example.com') }
      let(:response_body) { '' }
      let(:response_headers) { { 'content-type' => 'application/json' } }
      let(:search_path) { api_version == 3 ? 'search/jql' : 'search' }
      let(:expected_url_pattern) { %r{.*jira.example.com/rest/api/#{api_version}/#{search_path}.*} }

      before do
        stub_request(:get, expected_url_pattern).to_return(status: 200, body: response_body, headers: response_headers)
      end

      it_behaves_like 'a service that handles Jira API errors'

      context 'when jira runs on a subpath' do
        let(:jira_integration) { create(:jira_integration, url: 'http://jira.example.com/jira') }
        let(:expected_url_pattern) { %r{.*jira.example.com/jira/rest/api/#{api_version}/#{search_path}.*} }

        it 'takes the subpath into account' do
          expect(result.success?).to be_truthy
        end
      end

      it 'requests for default fields' do
        expect_next(JIRA::Client).to receive(:get)
          .with(include("fields=#{described_class::DEFAULT_FIELDS}"))
          .and_return({ 'issues' => [] })

        result
      end

      it 'uses the correct API version' do
        expect_next(JIRA::Client).to receive(:get)
          .with(include("/rest/api/#{api_version}/"))
          .and_return({ 'issues' => [] })

        result
      end
    end
  end
end
