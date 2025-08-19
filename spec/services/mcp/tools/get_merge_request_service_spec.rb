# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetMergeRequestService, feature_category: :mcp_server do
  let(:service) { described_class.new(name: 'get_merge_request') }

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq('Get a single merge request.')
    end
  end

  describe '#input_schema' do
    it 'returns the correct schema' do
      schema = service.input_schema

      expect(schema[:type]).to eq('object')
      expect(schema[:required]).to eq(%w[id merge_request_iid])
      expect(schema[:properties][:id][:type]).to eq('string')
      expect(schema[:properties][:id][:minLength]).to eq(1)
      expect(schema[:properties][:merge_request_iid][:type]).to eq('integer')
    end
  end

  describe '#execute' do
    let(:oauth_token) { 'token_123' }

    context 'with valid arguments' do
      let(:api_response) do
        instance_double(Gitlab::HTTP::Response, body: response_body, success?: success, code: response_code)
      end

      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(api_response)
      end

      context 'with successful response' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) do
          {
            'id' => 456,
            'iid' => 10,
            'title' => 'Test Merge Request',
            'state' => 'opened',
            'source_branch' => 'feature-branch',
            'target_branch' => 'main',
            'web_url' => 'https://gitlab.com/test-project/-/merge_requests/10'
          }.to_json
        end

        let(:arguments) do
          { id: 'test-project', merge_request_iid: 10 }
        end

        it 'returns success response' do
          result = service.execute(oauth_token, arguments)

          expect(result).to eq({
            content: [{ type: 'text', text: 'https://gitlab.com/test-project/-/merge_requests/10' }],
            structuredContent: {
              'id' => 456,
              'iid' => 10,
              'title' => 'Test Merge Request',
              'state' => 'opened',
              'source_branch' => 'feature-branch',
              'target_branch' => 'main',
              'web_url' => 'https://gitlab.com/test-project/-/merge_requests/10'
            },
            isError: false
          })
        end

        it 'makes request with correct URL' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end
      end

      context 'with project ID that needs encoding' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) do
          {}.to_json
        end

        let(:arguments) do
          { id: 'gitlab-org/gitlab', merge_request_iid: 123456 }
        end

        it 'URL encodes the project ID' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/gitlab-org%2Fgitlab/merge_requests/123456",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end
      end
    end

    context 'with missing required field' do
      let(:arguments) do
        { id: 'test-project' }
      end

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('merge_request_iid is missing')
      end
    end
  end
end
